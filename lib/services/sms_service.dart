// sms_service.dart - Enhanced with debugging
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef SmsCallback = void Function(String sender, String message, int timestamp);

class SmsListener {
  static const MethodChannel _channel = MethodChannel('sms_channel');
  static SmsCallback? _callback;
  static bool _isListening = false;

  static Future<bool> initialize() async {
    try {
      debugPrint("🔧 Initializing SMS listener...");

      // Test if the channel is working
      try {
        String? testResult = await _channel.invokeMethod('testReceiver');
        debugPrint("📱 Channel test result: $testResult");
      } catch (e) {
        debugPrint("❌ Channel test failed: $e");
      }

      // Check permissions
      bool hasPermissions = await _channel.invokeMethod('checkPermissions') ?? false;
      debugPrint("🔐 Has SMS permissions: $hasPermissions");

      if (!hasPermissions) {
        debugPrint("🔐 Requesting SMS permissions...");
        await _channel.invokeMethod('requestPermissions');
        return false; // Will get result via callback
      }

      debugPrint("✅ SMS permissions already granted");
      return true;
    } catch (e) {
      debugPrint("❌ Error initializing SMS listener: $e");
      return false;
    }
  }

  static void startListening(SmsCallback callback) {
    _callback = callback;
    _isListening = true;

    debugPrint("🎧 Starting SMS listening...");
    debugPrint("🎧 Callback set: ${_callback != null}");
    debugPrint("🎧 Is listening: $_isListening");

    _channel.setMethodCallHandler((call) async {
      debugPrint("📞 Method call received: ${call.method}");
      debugPrint("📞 Arguments: ${call.arguments}");

      switch (call.method) {
        case 'onSmsReceived':
          debugPrint("📨 SMS received callback triggered!");

          if (!_isListening) {
            debugPrint("⚠️ Not listening, ignoring SMS");
            return;
          }

          if (_callback == null) {
            debugPrint("❌ No callback set, ignoring SMS");
            return;
          }

          try {
            final args = call.arguments as Map<dynamic, dynamic>;
            final sender = args['sender']?.toString() ?? '';
            final message = args['message']?.toString() ?? '';
            final timestamp = args['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

            debugPrint("📨 SMS Details:");
            debugPrint("   👤 Sender: $sender");
            debugPrint("   📝 Message length: ${message.length}");
            debugPrint("   📝 Message preview: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}");
            debugPrint("   ⏰ Timestamp: $timestamp");

            _callback!(sender, message, timestamp);
            debugPrint("✅ SMS callback executed successfully");

          } catch (e) {
            debugPrint("❌ Error processing SMS: $e");
          }
          break;

        case 'onPermissionResult':
          final granted = call.arguments as bool? ?? false;
          debugPrint("🔐 Permission result: $granted");

          if (granted) {
            debugPrint("✅ SMS permissions granted!");
          } else {
            debugPrint("❌ SMS permissions denied");
          }
          break;

        default:
          debugPrint("⚠️ Unknown method call: ${call.method}");
      }
    });

    debugPrint("🎧 SMS listener setup complete");
  }

  static void stopListening() {
    _isListening = false;
    _callback = null;
    debugPrint("🛑 SMS listening stopped");
  }

  // Enhanced debugging for transaction detection
  static bool isTransactionMessage(String message) {
    debugPrint("🔍 Checking if transaction message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}");

    String lowerMsg = message.toLowerCase();

    List<String> transactionKeywords = [
      'debited', 'credited', 'sent', 'received', 'paid', 'withdrawn',
      'deposited', 'transferred', 'transaction', 'purchase', 'refund',
      'deducted', 'added', 'balance', 'account', 'upi', 'neft', 'imps',
      'rtgs', 'bank', 'atm', 'pos', 'online'
    ];

    bool isTransaction = transactionKeywords.any((keyword) => lowerMsg.contains(keyword));
    debugPrint("🔍 Is transaction: $isTransaction");

    if (isTransaction) {
      List<String> matchedKeywords = transactionKeywords.where((keyword) => lowerMsg.contains(keyword)).toList();
      debugPrint("🔍 Matched keywords: $matchedKeywords");
    }

    return isTransaction;
  }

  static bool isDebitMessage(String message) {
    String lowerMsg = message.toLowerCase();
    List<String> debitKeywords = [
      'debited', 'sent', 'paid', 'withdrawn', 'deducted',
      'purchase', 'spent', 'transfer to', 'payment', 'debit'
    ];

    bool isDebit = debitKeywords.any((keyword) => lowerMsg.contains(keyword));
    debugPrint("🔍 Is debit: $isDebit");
    return isDebit;
  }

  static bool isCreditMessage(String message) {
    String lowerMsg = message.toLowerCase();
    List<String> creditKeywords = [
      'credited', 'received', 'deposited', 'added',
      'refund', 'transfer from', 'salary', 'interest', 'credit'
    ];

    bool isCredit = creditKeywords.any((keyword) => lowerMsg.contains(keyword));
    debugPrint("🔍 Is credit: $isCredit");
    return isCredit;
  }

  static String extractMethod(String message) {
    debugPrint("🔍 Extracting method from message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}");

    String upperMsg = message.toUpperCase();
    List<String> methodKeywords = [
      'UPI', 'NEFT', 'IMPS', 'RTGS', 'BANK', 'ATM', 'POS', 'ONLINE'
    ];

    String method = 'UNKNOWN';

    for (String keyword in methodKeywords) {
      if (upperMsg.contains(keyword)) {
        method = keyword;
        break;
      }
    }

    debugPrint("🔍 Extracted method: $method");
    return method;
  }


  static double? extractAmount(String message) {
    debugPrint("💰 Extracting amount from: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}");

    List<RegExp> amountPatterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
      RegExp(r'amount[:\s]*(?:rs\.?|inr|₹)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:usd|dollar)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:^|\s)([0-9,]+(?:\.[0-9]{2})?)(?:\s|$)', caseSensitive: false), // Any number
    ];

    for (int i = 0; i < amountPatterns.length; i++) {
      RegExp pattern = amountPatterns[i];
      Match? match = pattern.firstMatch(message);
      if (match != null) {
        String amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        double? amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          debugPrint("💰 Amount found with pattern $i: ₹$amount");
          return amount;
        }
      }
    }

    debugPrint("💰 No valid amount found");
    return null;
  }

  static String extractBankName(String sender) {
    debugPrint("🏦 Extracting bank name from sender: $sender");

    Map<String, String> bankPatterns = {
      // Indian Banks
      'SBI': 'State Bank of India',
      'HDFC': 'HDFC Bank',
      'ICICI': 'ICICI Bank',
      'AXIS': 'Axis Bank',
      'PNB': 'Punjab National Bank',
      'BOB': 'Bank of Baroda',
      'UNION': 'Union Bank',
      'CANARA': 'Canara Bank',
      'IOB': 'Indian Overseas Bank',
      'KOTAK': 'Kotak Mahindra Bank',
      'YES': 'Yes Bank',
      'INDUS': 'IndusInd Bank',
      'FEDERAL': 'Federal Bank',
      'SOUTH': 'South Indian Bank',

      // Payment Services
      'PAYTM': 'Paytm',
      'GPAY': 'Google Pay',
      'PHONEPE': 'PhonePe',
      'MOBIKWIK': 'MobiKwik',
      'FREECHARGE': 'FreeCharge',
      'AMAZON': 'Amazon Pay',
      'WALMART': 'Walmart',
      'UPI': 'UPI Payment',

      // Credit Cards
      'AMEX': 'American Express',
      'VISA': 'Visa',
      'MASTER': 'Mastercard',
    };

    String upperSender = sender.toUpperCase();
    for (String pattern in bankPatterns.keys) {
      if (upperSender.contains(pattern)) {
        String bankName = bankPatterns[pattern]!;
        debugPrint("🏦 Bank identified: $bankName");
        return bankName;
      }
    }

    debugPrint("🏦 No bank pattern matched, using original sender");
    return sender;
  }

  static Map<String, dynamic>? parseTransactionSms(String sender, String message, int timestamp) {
    debugPrint("🔄 Parsing transaction SMS...");
    debugPrint("🔄 Sender: $sender");
    debugPrint("🔄 Message preview: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}");

    if (!isTransactionMessage(message)) {
      debugPrint("🔄 Not a transaction message");
      return null;
    }

    double? amount = extractAmount(message);
    if (amount == null) {
      debugPrint("🔄 No valid amount found, not a transaction");
      return null;
    }

    String transactionType;
    if (isDebitMessage(message)) {
      transactionType = 'debit';
    } else if (isCreditMessage(message)) {
      transactionType = 'credit';
    } else {
      transactionType = 'unknown';
    }

    String bankName = extractBankName(sender);

    String method = extractMethod(message);

    Map<String, dynamic> transaction = {
      'type': transactionType,
      'amount': amount,
      'sender': sender,
      'bankName': bankName,
      'message': message,
      'method': method,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      'rawTimestamp': timestamp,
    };

    debugPrint("✅ Transaction parsed successfully:");
    debugPrint("   Type: ${transaction['type']}");
    debugPrint("   Amount: ₹${transaction['amount']}");
    debugPrint("   Bank: ${transaction['bankName']}");
    debugPrint("   Method: ${transaction['method']}");

    return transaction;
  }
}