package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log
import kotlinx.coroutines.*

class SmsReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SmsReceiver"
        private const val PREF_NAME = "sms_parser_prefs"
        private const val KEY_SMS_PARSING_ENABLED = "sms_parsing_enabled"

        // Battery optimization: Throttle SMS processing
        private var lastProcessedTime = 0L
        private const val MIN_PROCESS_INTERVAL = 1500L // 1.5 seconds between SMS

        // Known bank/payment service senders (Indian context)
        private val KNOWN_SENDERS = setOf(
            "HDFCBK", "ICICIB", "SBIINB", "AXISBK", "KOTAKB",
            "PNBSMS", "BOISMS", "INDBNK", "CANBNK", "UNIONB",
            "PAYTM", "GPAY", "PHONEPE", "AMAZON", "AMEXIN",
            "SCBANK", "YESBNK", "IDBIBN", "FEDBAK", "RBLBNK",
            "VM-", "VK-", "BP-", "JM-", "AX-", "AD-"
        )

        // Quick transaction keywords for filtering
        private val TRANSACTION_KEYWORDS = setOf(
            "debited", "credited", "spent", "paid", "withdrawn",
            "purchase", "payment", "transaction", "sent", "received",
            "rs.", "rs", "inr", "₹", "debit", "credit"
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Battery check: Is SMS parsing enabled?
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SMS_PARSING_ENABLED, true)) {
            Log.d(TAG, "SMS parsing disabled by user")
            return
        }

        // Battery optimization: Throttle rapid SMS processing
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastProcessedTime < MIN_PROCESS_INTERVAL) {
            Log.d(TAG, "SMS processing throttled (too frequent)")
            return
        }

        Log.d(TAG, "SMS Receiver triggered")

        when (intent.action) {
            "android.provider.Telephony.SMS_RECEIVED",
            Telephony.Sms.Intents.SMS_RECEIVED_ACTION -> {
                lastProcessedTime = currentTime
                handleSmsReceived(context, intent)
            }
            else -> {
                Log.w(TAG, "Unknown action: ${intent.action}")
            }
        }
    }

    private fun handleSmsReceived(context: Context, intent: Intent) {
        val bundle: Bundle? = intent.extras
        if (bundle == null) {
            Log.e(TAG, "Bundle is null")
            return
        }

        try {
            val pdus = bundle.get("pdus") as? Array<*>
            if (pdus == null || pdus.isEmpty()) {
                Log.e(TAG, "PDUs array is null or empty")
                return
            }

            val format = bundle.getString("format")

            // Battery optimization: Process only first PDU for multi-part SMS
            // Most transaction SMS are single-part
            val pdu = pdus[0]

            val sms = if (format != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                SmsMessage.createFromPdu(pdu as ByteArray, format)
            } else {
                @Suppress("DEPRECATION")
                SmsMessage.createFromPdu(pdu as ByteArray)
            }

            if (sms == null) {
                Log.e(TAG, "Failed to create SmsMessage")
                return
            }

            val message = sms.messageBody ?: ""
            val sender = sms.originatingAddress ?: ""
            val timestamp = sms.timestampMillis

            // Battery optimization: Quick filter before processing
            if (!shouldProcess(sender, message)) {
                Log.d(TAG, "SMS filtered out - not a transaction (sender: $sender)")
                return
            }

            Log.d(TAG, "Processing transaction SMS from: $sender")

            // Use coroutine for async processing to avoid blocking broadcast
            CoroutineScope(Dispatchers.Default).launch {
                try {
                    sendToFlutter(sender, message, timestamp)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in async processing: ${e.message}")
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error processing SMS: ${e.message}", e)
        }
    }

    /**
     * Battery optimization: Filter SMS to process only relevant transaction messages
     */
    private fun shouldProcess(sender: String, message: String): Boolean {
        // Quick check 1: Is sender known?
        val senderUpper = sender.uppercase()
        val isKnownSender = KNOWN_SENDERS.any { senderUpper.contains(it) }

        if (!isKnownSender) {
            // Allow numeric senders (6-digit short codes like banks use)
            val isShortCode = sender.matches(Regex("""^\d{4,6}$"""))
            if (!isShortCode) {
                return false
            }
        }

        // Quick check 2: Does message contain transaction keywords?
        val messageLower = message.lowercase()
        val hasTransactionKeyword = TRANSACTION_KEYWORDS.any {
            messageLower.contains(it)
        }

        if (!hasTransactionKeyword) {
            return false
        }

        // Quick check 3: Does it have amount pattern?
        val hasAmount = message.contains(Regex("""(?:rs\.?|inr|₹)\s*\d""", RegexOption.IGNORE_CASE)) ||
                message.contains(Regex("""\d+(?:\.\d{2})?\s*(?:rs\.?|inr|₹)""", RegexOption.IGNORE_CASE))

        return hasAmount
    }

    private suspend fun sendToFlutter(sender: String, message: String, timestamp: Long) = withContext(Dispatchers.Main) {
        try {
            // Check if Flutter is ready
            if (!MainActivity.isChannelReady()) {
                Log.e(TAG, "Flutter channel not ready - queuing SMS")
                // TODO: Consider implementing a queue for SMS when app is not ready
                return@withContext
            }

            val data = mapOf(
                "sender" to sender,
                "message" to message,
                "timestamp" to timestamp
            )

            MainActivity.sendSmsToFlutter(data)
            Log.d(TAG, "SMS sent to Flutter successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error sending to Flutter: ${e.message}", e)
        }
    }
}