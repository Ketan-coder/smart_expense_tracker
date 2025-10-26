import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef SmsCallback = void Function(String sender, String message, int timestamp);

class SmsListener {
  // CRITICAL FIX: Use the correct channel name matching MainActivity
  static const MethodChannel _channel = MethodChannel('com.example.expense_tracker/sms');
  static SmsCallback? _callback;
  static bool _isListening = false;

  static Future<bool> initialize() async {
    try {
      debugPrint("🔧 Initializing SMS listener...");
      debugPrint("🔧 Channel name: com.example.expense_tracker/sms");

      // Set up method call handler FIRST before any other operations
      _setupMethodCallHandler();

      // Test if the channel is working
      try {
        String? testResult = await _channel.invokeMethod('testReceiver');
        debugPrint("📱 Channel test result: $testResult");
      } catch (e) {
        debugPrint("⚠️ Channel test failed (this is OK if method doesn't exist): $e");
      }

      // Check permissions
      try {
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
        debugPrint("⚠️ Permission check failed (may not be implemented): $e");
        // Assume permissions are granted if check fails
        return true;
      }

    } catch (e) {
      debugPrint("❌ Error initializing SMS listener: $e");
      return false;
    }
  }

  static void _setupMethodCallHandler() {
    debugPrint("🎧 Setting up method call handler...");

    _channel.setMethodCallHandler((call) async {
      debugPrint("📞 ========================================");
      debugPrint("📞 Method call received: ${call.method}");
      debugPrint("📞 Arguments type: ${call.arguments.runtimeType}");
      debugPrint("📞 Arguments: ${call.arguments}");
      debugPrint("📞 ========================================");

      switch (call.method) {
        case 'onSmsReceived':
          debugPrint("📨 SMS received callback triggered!");
          debugPrint("📨 Listening status: $_isListening");
          debugPrint("📨 Callback set: ${_callback != null}");

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
            debugPrint("📨 Parsing arguments...");
            debugPrint("📨 Raw sender: ${args['sender']}");
            debugPrint("📨 Raw message: ${args['message']}");
            debugPrint("📨 Raw timestamp: ${args['timestamp']}");

            final sender = args['sender']?.toString() ?? '';
            final message = args['message']?.toString() ?? '';
            final timestamp = args['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

            debugPrint("📨 Parsed SMS Details:");
            debugPrint("   👤 Sender: $sender");
            debugPrint("   📝 Message length: ${message.length}");
            debugPrint("   📝 Message preview: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}");
            debugPrint("   ⏰ Timestamp: $timestamp");
            debugPrint("   ⏰ DateTime: ${DateTime.fromMillisecondsSinceEpoch(timestamp)}");

            debugPrint("📨 Calling callback function...");
            _callback!(sender, message, timestamp);
            debugPrint("✅ SMS callback executed successfully");

          } catch (e, stackTrace) {
            debugPrint("❌ Error processing SMS: $e");
            debugPrint("❌ Stack trace: $stackTrace");
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

    debugPrint("✅ Method call handler setup complete");
  }

  static void startListening(SmsCallback callback) {
    _callback = callback;
    _isListening = true;

    debugPrint("🎧 ========================================");
    debugPrint("🎧 Starting SMS listening...");
    debugPrint("🎧 Callback set: ${_callback != null}");
    debugPrint("🎧 Is listening: $_isListening");
    debugPrint("🎧 Channel: com.example.expense_tracker/sms");
    debugPrint("🎧 ========================================");

    // Ensure handler is set up
    _setupMethodCallHandler();

    debugPrint("🎧 SMS listener ready and waiting for messages");
  }

  static void stopListening() {
    _isListening = false;
    _callback = null;
    debugPrint("🛑 SMS listening stopped");
  }

  // Enhanced debugging for transaction detection
  static bool isTransactionMessage(String message) {
    debugPrint("🔍 ========================================");
    debugPrint("🔍 Checking if transaction message...");
    debugPrint("🔍 Message: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}");

    String lowerMsg = message.toLowerCase();

    List<String> transactionKeywords = [
      'debited', 'credited', 'sent', 'received', 'paid', 'withdrawn',
      'deposited', 'transferred', 'transaction', 'purchase', 'refund',
      'deducted', 'added', 'balance', 'account', 'upi', 'neft', 'imps',
      'rtgs', 'bank', 'atm', 'pos', 'online'
    ];

    List<String> matchedKeywords = transactionKeywords.where((keyword) => lowerMsg.contains(keyword)).toList();
    bool isTransaction = matchedKeywords.isNotEmpty;

    debugPrint("🔍 Is transaction: $isTransaction");
    if (isTransaction) {
      debugPrint("🔍 Matched keywords: $matchedKeywords");
    }
    debugPrint("🔍 ========================================");

    return isTransaction;
  }

  static bool isDebitMessage(String message) {
    String lowerMsg = message.toLowerCase();
    List<String> debitKeywords = [
      'debited', 'sent', 'paid', 'withdrawn', 'deducted',
      'purchase', 'spent', 'transfer to', 'payment', 'debit'
    ];

    List<String> matchedKeywords = debitKeywords.where((keyword) => lowerMsg.contains(keyword)).toList();
    bool isDebit = matchedKeywords.isNotEmpty;

    debugPrint("🔍 Is debit: $isDebit");
    if (isDebit) {
      debugPrint("🔍 Matched debit keywords: $matchedKeywords");
    }
    return isDebit;
  }

  static bool isCreditMessage(String message) {
    String lowerMsg = message.toLowerCase();
    List<String> creditKeywords = [
      'credited', 'received', 'deposited', 'added',
      'refund', 'transfer from', 'salary', 'interest', 'credit'
    ];

    List<String> matchedKeywords = creditKeywords.where((keyword) => lowerMsg.contains(keyword)).toList();
    bool isCredit = matchedKeywords.isNotEmpty;

    debugPrint("🔍 Is credit: $isCredit");
    if (isCredit) {
      debugPrint("🔍 Matched credit keywords: $matchedKeywords");
    }
    return isCredit;
  }

  static String extractMethod(String message) {
    debugPrint("🔍 Extracting payment method from message...");

    String upperMsg = message.toUpperCase();
    List<String> methodKeywords = [
      'UPI', 'NEFT', 'IMPS', 'RTGS', 'BANK', 'ATM', 'POS', 'ONLINE', 'DEBIT CARD', 'CREDIT CARD'
    ];

    String method = 'OTHER';

    for (String keyword in methodKeywords) {
      if (upperMsg.contains(keyword)) {
        method = keyword;
        debugPrint("🔍 Found method: $method");
        break;
      }
    }

    if (method == 'OTHER') {
      debugPrint("🔍 No specific method found, defaulting to: $method");
    }

    return method;
  }

  static double? extractAmount(String message) {
    debugPrint("💰 ========================================");
    debugPrint("💰 Extracting amount from message...");
    debugPrint("💰 Message: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}");

    List<RegExp> amountPatterns = [
      // Indian Rupee patterns
      RegExp(r'(?:rs\.?\s*|inr\s*|₹\s*)([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),

      // Amount with label
      RegExp(r'amount[:\s]*(?:rs\.?|inr|₹)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),

      // USD/Dollar
      RegExp(r'(?:usd|dollar)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),

      // Generic number (last resort)
      RegExp(r'(?:^|\s)([0-9,]+\.[0-9]{2})(?:\s|$)', caseSensitive: false),
    ];

    for (int i = 0; i < amountPatterns.length; i++) {
      RegExp pattern = amountPatterns[i];
      Match? match = pattern.firstMatch(message);
      if (match != null) {
        String amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        debugPrint("💰 Pattern $i matched: $amountStr");

        double? amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          debugPrint("💰 ✅ Valid amount found: ₹$amount");
          debugPrint("💰 ========================================");
          return amount;
        } else {
          debugPrint("💰 ❌ Invalid amount after parsing: $amount");
        }
      }
    }

    debugPrint("💰 ❌ No valid amount found in message");
    debugPrint("💰 ========================================");
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
      'IDBI': 'IDBI Bank',
      'BOI': 'Bank of India',
      'CENTRAL': 'Central Bank',

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
      'RUPAY': 'RuPay',
    };

    String upperSender = sender.toUpperCase();
    for (String pattern in bankPatterns.keys) {
      if (upperSender.contains(pattern)) {
        String bankName = bankPatterns[pattern]!;
        debugPrint("🏦 Bank identified: $bankName (pattern: $pattern)");
        return bankName;
      }
    }

    debugPrint("🏦 No bank pattern matched, using sender: $sender");
    return sender;
  }

  static Map<String, dynamic>? parseTransactionSms(String sender, String message, int timestamp) {
    debugPrint("🔄 ========================================");
    debugPrint("🔄 PARSING TRANSACTION SMS");
    debugPrint("🔄 ========================================");
    debugPrint("🔄 Sender: $sender");
    debugPrint("🔄 Full message: $message");
    debugPrint("🔄 Timestamp: $timestamp");

    // Step 1: Check if transaction message
    if (!isTransactionMessage(message)) {
      debugPrint("🔄 ❌ Not identified as transaction message");
      debugPrint("🔄 ========================================");
      return null;
    }
    debugPrint("🔄 ✅ Identified as transaction message");

    // Step 2: Extract amount
    double? amount = extractAmount(message);
    if (amount == null) {
      debugPrint("🔄 ❌ No valid amount found, cannot process");
      debugPrint("🔄 ========================================");
      return null;
    }
    debugPrint("🔄 ✅ Amount extracted: ₹$amount");

    // Step 3: Determine transaction type
    String transactionType;
    if (isDebitMessage(message)) {
      transactionType = 'debit';
      debugPrint("🔄 ✅ Type: DEBIT (expense)");
    } else if (isCreditMessage(message)) {
      transactionType = 'credit';
      debugPrint("🔄 ✅ Type: CREDIT (income)");
    } else {
      transactionType = 'unknown';
      debugPrint("🔄 ⚠️ Type: UNKNOWN (defaulting to debit)");
      // Default to debit if unclear
      transactionType = 'debit';
    }

    // Step 4: Extract additional info
    String bankName = extractBankName(sender);
    String method = extractMethod(message);

    // Step 5: Create transaction object
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

    debugPrint("🔄 ========================================");
    debugPrint("🔄 ✅ TRANSACTION PARSED SUCCESSFULLY");
    debugPrint("🔄 ========================================");
    debugPrint("🔄 Type: ${transaction['type']}");
    debugPrint("🔄 Amount: ₹${transaction['amount']}");
    debugPrint("🔄 Bank: ${transaction['bankName']}");
    debugPrint("🔄 Method: ${transaction['method']}");
    debugPrint("🔄 Date: ${transaction['timestamp']}");
    debugPrint("🔄 ========================================");

    return transaction;
  }
}