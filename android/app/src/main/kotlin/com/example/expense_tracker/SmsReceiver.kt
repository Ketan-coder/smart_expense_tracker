package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SmsReceiver", "=== SMS RECEIVER TRIGGERED ===")
        Log.d("SmsReceiver", "Intent action: ${intent.action}")
        Log.d("SmsReceiver", "Intent extras: ${intent.extras?.keySet()}")

        // Handle both old and new SMS intent actions
        when (intent.action) {
            "android.provider.Telephony.SMS_RECEIVED",
            Telephony.Sms.Intents.SMS_RECEIVED_ACTION -> {
                handleSmsReceived(context, intent)
            }
            else -> {
                Log.w("SmsReceiver", "Unknown action received: ${intent.action}")
            }
        }
    }

    private fun handleSmsReceived(context: Context, intent: Intent) {
        Log.d("SmsReceiver", "Processing SMS_RECEIVED intent")

        val bundle: Bundle? = intent.extras
        if (bundle == null) {
            Log.e("SmsReceiver", "Bundle is null!")
            return
        }

        Log.d("SmsReceiver", "Bundle keys: ${bundle.keySet()}")

        try {
            val pdus = bundle.get("pdus") as? Array<*>
            if (pdus == null) {
                Log.e("SmsReceiver", "PDUs array is null!")
                return
            }

            Log.d("SmsReceiver", "Found ${pdus.size} PDU(s)")

            val format = bundle.getString("format")
            Log.d("SmsReceiver", "SMS format: $format")

            pdus.forEachIndexed { index, pdu ->
                try {
                    Log.d("SmsReceiver", "Processing PDU $index")

                    val sms = if (format != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        SmsMessage.createFromPdu(pdu as ByteArray, format)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsMessage.createFromPdu(pdu as ByteArray)
                    }

                    if (sms == null) {
                        Log.e("SmsReceiver", "Failed to create SmsMessage from PDU $index")
                        return@forEachIndexed
                    }

                    val message = sms.messageBody ?: ""
                    val sender = sms.originatingAddress ?: ""
                    val timestamp = sms.timestampMillis

                    Log.d("SmsReceiver", "SMS Details:")
                    Log.d("SmsReceiver", "  Sender: $sender")
                    Log.d("SmsReceiver", "  Message length: ${message.length}")
                    Log.d("SmsReceiver", "  Message preview: ${message.take(50)}...")
                    Log.d("SmsReceiver", "  Timestamp: $timestamp")

                    // Send to Flutter
                    sendToFlutter(sender, message, timestamp)

                } catch (e: Exception) {
                    Log.e("SmsReceiver", "Error processing PDU $index: ${e.message}", e)
                }
            }

        } catch (e: Exception) {
            Log.e("SmsReceiver", "Error processing SMS bundle: ${e.message}", e)
        }
    }

    private fun sendToFlutter(sender: String, message: String, timestamp: Long) {
        try {
            Log.d("SmsReceiver", "Attempting to send to Flutter...")

            if (!MainActivity.isChannelReady()) {
                Log.e("SmsReceiver", "Flutter channel not ready!")
                return
            }

            val data = mapOf(
                "sender" to sender,
                "message" to message,
                "timestamp" to timestamp
            )

            MainActivity.sendSmsToFlutter(data)
            Log.d("SmsReceiver", "Successfully sent SMS to Flutter")

        } catch (e: Exception) {
            Log.e("SmsReceiver", "Error sending to Flutter: ${e.message}", e)
        }
    }
}