package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Durable, process-wide SMS queue. One lock shared by every caller
 * (the old per-instance synchronized(this) did not actually exclude anything,
 * because MainActivity creates a fresh SmsReceiver() for every call).
 */
object SmsQueue {
    private const val PREF_NAME = "sms_pending_queue"
    private const val KEY_ITEMS = "items"
    private const val MAX_ITEMS = 200
    private val lock = Any()

    fun makeId(sender: String, message: String, timestamp: Long): String =
        "$timestamp:${sender.hashCode()}:${message.hashCode()}"

    /** Persists the SMS (commit = synchronous disk write) and returns its id. */
    fun enqueue(context: Context, sender: String, message: String, timestamp: Long): String {
        val id = makeId(sender, message, timestamp)
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_ITEMS, "[]"))
            for (i in 0 until queue.length()) {
                if (queue.optJSONObject(i)?.optString("id") == id) return id
            }
            queue.put(
                JSONObject()
                    .put("id", id)
                    .put("sender", sender)
                    .put("message", message)
                    .put("timestamp", timestamp)
            )
            val out = if (queue.length() > MAX_ITEMS) {
                val trimmed = JSONArray()
                for (i in queue.length() - MAX_ITEMS until queue.length()) trimmed.put(queue.get(i))
                trimmed
            } else queue
            prefs.edit().putString(KEY_ITEMS, out.toString()).commit()
        }
        return id
    }

    fun getAll(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_ITEMS, "[]"))
            return (0 until queue.length()).mapNotNull { index ->
                val item = queue.optJSONObject(index) ?: return@mapNotNull null
                mapOf(
                    "id" to item.optString("id"),
                    "sender" to item.optString("sender"),
                    "message" to item.optString("message"),
                    "timestamp" to item.optLong("timestamp")
                )
            }
        }
    }

    fun ack(context: Context, ids: List<String>): Boolean {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_ITEMS, "[]"))
            val remaining = JSONArray()
            for (i in 0 until queue.length()) {
                val item = queue.optJSONObject(i) ?: continue
                if (!ids.contains(item.optString("id"))) remaining.put(item)
            }
            return prefs.edit().putString(KEY_ITEMS, remaining.toString()).commit()
        }
    }
}

/** Reads the system SMS inbox (needs READ_SMS). Used to catch anything the receiver missed. */
object SmsInbox {
    fun readSince(context: Context, sinceMs: Long, limit: Int = 2000): List<Map<String, Any>> {
        val out = ArrayList<Map<String, Any>>()
        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.DATE_SENT
        )
        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            "${Telephony.Sms.DATE} >= ?",
            arrayOf(sinceMs.toString()),
            "${Telephony.Sms.DATE} ASC"
        )?.use { c ->
            while (c.moveToNext() && out.size < limit) {
                val date = c.getLong(2)
                val sent = c.getLong(3)
                out.add(
                    mapOf(
                        "sender" to (c.getString(0) ?: ""),
                        "message" to (c.getString(1) ?: ""),
                        // date_sent is the SMSC timestamp, the same value the live receiver reports
                        "timestamp" to (if (sent > 0) sent else date)
                    )
                )
            }
        }
        return out
    }
}

class SmsReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SmsReceiver"
        private const val KEY_SMS_PARSING_ENABLED = "sms_parsing_enabled"

        private val AMOUNT_BEFORE = Regex("""(?<![a-z])(?:rs\.?|inr|₹)\s*\d""", RegexOption.IGNORE_CASE)
        private val AMOUNT_AFTER = Regex("""\d[\d,]*(?:\.\d{1,2})?\s*(?:rs\.?|inr|₹)""", RegexOption.IGNORE_CASE)

        // Deliberately permissive: this only decides "is it worth queueing".
        // The strict parsing/filtering happens in Dart.
        private val KEYWORDS = listOf(
            "debited", "credited", "debit", "credit", "spent", "paid", "sent",
            "received", "withdrawn", "deposited", "purchase", "payment",
            "transaction", "txn", "upi", "a/c", "transfer", "refund"
        )
    }

    // Kept so MainActivity (which calls SmsReceiver().xxx) compiles unchanged.
    fun enqueuePendingSms(context: Context, sender: String, message: String, timestamp: Long) {
        SmsQueue.enqueue(context, sender, message, timestamp)
    }

    fun getPendingSms(context: Context): List<Map<String, Any>> = SmsQueue.getAll(context)

    fun ackPendingSms(context: Context, ids: List<String>): Boolean = SmsQueue.ack(context, ids)

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.$KEY_SMS_PARSING_ENABLED", true)) {
            Log.d(TAG, "SMS parsing disabled by user")
            return
        }

        try {
            val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (parts.isNullOrEmpty()) return

            // A long SMS arrives as several parts in ONE broadcast; join them per sender.
            val bodies = LinkedHashMap<String, StringBuilder>()
            val timestamps = HashMap<String, Long>()
            for (part in parts) {
                val sender = part.originatingAddress ?: ""
                bodies.getOrPut(sender) { StringBuilder() }.append(part.messageBody ?: "")
                if (!timestamps.containsKey(sender)) timestamps[sender] = part.timestampMillis
            }

            for ((sender, body) in bodies) {
                val message = body.toString()
                val timestamp = timestamps[sender] ?: System.currentTimeMillis()

                if (!shouldProcess(message)) {
                    Log.d(TAG, "SMS filtered out (sender: $sender)")
                    continue
                }

                // 1) PERSIST FIRST (synchronous). Nothing below can lose the SMS.
                val id = SmsQueue.enqueue(context, sender, message, timestamp)
                Log.d(TAG, "Queued SMS $id from $sender")

                // 2) Best-effort live delivery. onReceive runs on the main thread,
                //    which is where MethodChannel calls must happen.
                if (MainActivity.isChannelReady()) {
                    MainActivity.sendSmsToFlutter(
                        mapOf(
                            "id" to id,
                            "sender" to sender,
                            "message" to message,
                            "timestamp" to timestamp
                        )
                    )
                } else {
                    Log.d(TAG, "Flutter not ready - SMS stays queued for replay")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing SMS: ${e.message}", e)
        }
    }

    private fun shouldProcess(message: String): Boolean {
        val hasAmount = AMOUNT_BEFORE.containsMatchIn(message) || AMOUNT_AFTER.containsMatchIn(message)
        if (!hasAmount) return false
        val lower = message.lowercase()
        return KEYWORDS.any { lower.contains(it) }
    }
}