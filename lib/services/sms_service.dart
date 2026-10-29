import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef SmsCallback =
FutureOr<void> Function(String sender, String message, int timestamp);

class SmsListener {
  // Must match SMS_CHANNEL in MainActivity.
  static const MethodChannel _channel = MethodChannel(
    'com.example.expense_tracker/sms',
  );
  static SmsCallback? _callback;
  static bool _isListening = false;

  // Drain coordination.
  static bool _draining = false;
  static bool _drainAgain = false;

  // Queue ids currently being processed (live path or drain), so the same
  // queued SMS is never processed twice concurrently.
  static final Set<String> _inFlight = <String>{};

  static bool get isReady => _isListening && _callback != null;

  // ---------------------------------------------------------------------
  // Channel plumbing
  // ---------------------------------------------------------------------

  static Future<bool> initialize() async {
    try {
      debugPrint("🔧 Initializing SMS listener...");
      _setupMethodCallHandler();

      try {
        String? testResult = await _channel.invokeMethod('testReceiver');
        debugPrint("📱 Channel test result: $testResult");
      } catch (e) {
        debugPrint("⚠️ Channel test failed (OK if method doesn't exist): $e");
      }

      try {
        bool hasPermissions =
            await _channel.invokeMethod('checkPermissions') ?? false;
        debugPrint("🔐 Has SMS permissions: $hasPermissions");

        if (!hasPermissions) {
          debugPrint("🔐 Requesting SMS permissions...");
          await _channel.invokeMethod('requestPermissions');
          return false; // Result arrives via onPermissionResult
        }
        return true;
      } catch (e) {
        debugPrint("⚠️ Permission check failed (may not be implemented): $e");
        return true;
      }
    } catch (e) {
      debugPrint("❌ Error initializing SMS listener: $e");
      return false;
    }
  }

  static void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSmsReceived':
          await _handleIncomingSms(call.arguments);
          break;

        case 'onPermissionResult':
          final granted = call.arguments as bool? ?? false;
          debugPrint("🔐 Permission result: $granted");
          if (granted && isReady) unawaited(drainPendingMessages());
          break;

        default:
          debugPrint("⚠️ Unknown method call: ${call.method}");
      }
    });
  }

  static Future<void> _handleIncomingSms(dynamic arguments) async {
    final args = Map<dynamic, dynamic>.from(arguments as Map);
    final id = args['id']?.toString();

    // Not ready: native already persisted it (when it sent an id), so it will
    // be replayed by the drain in startListening(). Only legacy callers
    // without an id need to be queued from here.
    if (!isReady) {
      debugPrint("⚠️ Not ready, SMS stays queued for replay");
      if (id == null) await _queueNatively(arguments);
      return;
    }

    if (id != null && !_inFlight.add(id)) return; // already being processed

    try {
      await _callback!(
        args['sender']?.toString() ?? '',
        args['message']?.toString() ?? '',
        (args['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );
      if (id != null) await _ack(id);
    } catch (e, stackTrace) {
      debugPrint("❌ Error processing SMS: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      // With an id it is still in the native queue and will be retried.
      if (id == null) await _queueNatively(arguments);
    } finally {
      if (id != null) _inFlight.remove(id);
    }
  }

  static Future<void> _queueNatively(dynamic arguments) async {
    try {
      await _channel.invokeMethod('queuePendingSms', arguments);
    } catch (e) {
      debugPrint("❌ Failed to queue SMS natively: $e");
    }
  }

  static Future<void> _ack(String id) async {
    try {
      await _channel.invokeMethod('ackPendingSms', <String, dynamic>{
        'ids': <String>[id],
      });
    } catch (e) {
      debugPrint("⚠️ Ack failed for $id: $e");
    }
  }

  static void startListening(SmsCallback callback) {
    _callback = callback;
    _isListening = true;
    debugPrint("🎧 Starting SMS listening (callback registered)");
    _setupMethodCallHandler();
    unawaited(drainPendingMessages(callback));
  }

  static void stopListening([SmsCallback? callback]) {
    // A disposed screen must not stop a newer screen's listener.
    if (callback != null && _callback != callback) return;
    _isListening = false;
    _callback = null;
    debugPrint("🛑 SMS listening stopped");
  }

  /// Replays SMS queued natively while Dart wasn't ready. An item is
  /// acknowledged only after the callback finished successfully. Safe to call
  /// repeatedly (start, resume, ...).
  static Future<void> drainPendingMessages([SmsCallback? callback]) async {
    final cb = callback ?? _callback;
    if (cb == null) return;

    if (_draining) {
      _drainAgain = true;
      return;
    }

    _draining = true;
    try {
      do {
        _drainAgain = false;
        await _drainOnce(cb);
      } while (_drainAgain);
    } finally {
      _draining = false;
    }
  }

  static Future<void> _drainOnce(SmsCallback callback) async {
    List<dynamic>? pending;
    try {
      pending = await _channel.invokeMethod<List<dynamic>>('getPendingSms');
    } catch (e) {
      debugPrint('⚠️ Pending SMS fetch failed: $e');
      return;
    }
    if (pending == null || pending.isEmpty) return;

    debugPrint("📥 Draining ${pending.length} pending SMS");

    for (final raw in pending) {
      String? id;
      try {
        final item = Map<dynamic, dynamic>.from(raw as Map);
        id = item['id']?.toString();
        if (id == null) continue;
        if (!_inFlight.add(id)) {
          id = null; // someone else owns it; don't remove their marker
          continue;
        }

        await callback(
          item['sender']?.toString() ?? '',
          item['message']?.toString() ?? '',
          (item['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        );
        await _ack(id);
      } catch (e, stackTrace) {
        // One bad message must not block the rest; it stays queued.
        debugPrint('⚠️ Pending SMS item failed: $e');
        debugPrint('$stackTrace');
      } finally {
        if (id != null) _inFlight.remove(id);
      }
    }
  }

  /// SMS in the system inbox with date >= [sinceMs], oldest first.
  /// Returns null when the inbox could not be read (permission, old native
  /// build without the method, ...) so callers don't advance their sync marker.
  static Future<List<Map<String, dynamic>>?> readInboxSince(int sinceMs) async {
    try {
      final rows = await _channel.invokeMethod<List<dynamic>>(
        'getInboxSince',
        <String, dynamic>{'since': sinceMs},
      );
      return (rows ?? <dynamic>[])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Inbox read failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------

  // Messages that mention money but are NOT a completed transaction.
  static final RegExp _notATransaction = RegExp(
    r'\botp\b|one[\s-]?time\s+(?:password|pin)|\bdo not share\b|\bnever share\b'
    r'|\bwill be (?:debited|deducted|charged)\b|\bis due\b|\bdue (?:on|by|date)\b'
    r'|\bminimum (?:amount )?due\b|\bpayment request\b|\bcollect request\b'
    r'|\brequested\b|\bfailed\b|\bdeclined\b|\bunsuccessful\b|\bnot successful\b',
    caseSensitive: false,
  );

  // "credit card" / "debit card" must not count as a direction keyword.
  static final RegExp _cardPhrase = RegExp(
    r'\b(?:debit|credit)\s*(?:/\s*(?:debit|credit)\s*)?cards?\b',
    caseSensitive: false,
  );

  static final RegExp _debitRe = RegExp(
    r'\b(?:debited|debit|sent|paid|withdrawn|withdrawal|deducted|spent|purchased?|charged|transfer(?:red)? to|used (?:at|for|on))\b',
    caseSensitive: false,
  );

  static final RegExp _creditRe = RegExp(
    r'\b(?:credited|credit|received|deposited|refund(?:ed)?|transfer(?:red)? from|added to|cashback)\b',
    caseSensitive: false,
  );

  static final RegExp _amountRe = RegExp(
    r'(?<![a-z])(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)'
    r'|([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:rs\b\.?|inr\b|₹)',
    caseSensitive: false,
  );

  static final RegExp _balanceContext = RegExp(
    r'\b(?:bal(?:ance)?|avl|avail(?:able)?|limit|outstanding)\b',
    caseSensitive: false,
  );

  static final RegExp _refRe = RegExp(
    r'(?:upi\s*)?(?:ref(?:erence)?|rrn|utr)(?:\s*(?:no|number|id))?\.?\s*[:#\-]?\s*([0-9]{6,})',
    caseSensitive: false,
  );

  // Banks send from alphanumeric headers (JD-KOTAKB-S). A plain phone number
  // is a person, not a bank alert.
  static final RegExp _personalNumber = RegExp(r'^\+\d{8,}$|^\d{10,}$');

  // TRAI headers: -P = promotional, -S/-T = service/transactional.
  static final RegExp _promoSender = RegExp(r'-P$', caseSensitive: false);

// Promo wording that mentions money but isn't a completed transaction.
  static final RegExp _promoText = RegExp(
    r'\bclick here\b|https?://|\bt\s*&\s*c\b|\bapply\b|\beligible\b'
    r'|\bpre[\s-]?approved\b|\boffer\b|\binstantly\b|\bto receive\b|\band receive\b'
    r'|\bavail\b|\bwin\b|\bcongratulations\b|\bvoucher\b|\bcoupon\b',
    caseSensitive: false,
  );

// Proof that a real account/instrument was affected. Bare "account" is
// deliberately NOT here ("credited in your account" is promo wording).
  static final RegExp _txnEvidence = RegExp(
    r'\ba/c\b|\bacct?\b|\b(?:x{2,}|\*{2,})\s?\d{3,4}\b|\bupi\b'
    r'|\b(?:ref|rrn|utr)\b|\bcard\s+(?:no|ending)\b'
    r'|\b(?:imps|neft|rtgs|atm|pos)\b|\bavl\b|\bbal(?:ance)?\b',
    caseSensitive: false,
  );

  static bool _looksPromotional(String sender, String message) {
    if (_promoSender.hasMatch(sender.trim())) return true;
    if (_promoText.hasMatch(message) && !_txnEvidence.hasMatch(message)) {
      return true;
    }
    return !_txnEvidence.hasMatch(message); // no proof of a real transaction
  }

  static String? _direction(String message) {
    final cleaned = message.replaceAll(_cardPhrase, ' ');
    final d = _debitRe.firstMatch(cleaned);
    final c = _creditRe.firstMatch(cleaned);
    if (d == null && c == null) return null;
    if (c == null) return 'debit';
    if (d == null) return 'credit';
    // Both present: the earliest strong keyword describes the user's account
    // ("Rs.500 debited from A/c ... credited to merchant").
    return d.start <= c.start ? 'debit' : 'credit';
  }

  static bool isTransactionMessage(String message) {
    if (_notATransaction.hasMatch(message)) return false;
    if (!_txnEvidence.hasMatch(message)) return false;
    return extractAmount(message) != null && _direction(message) != null;
  }

  static bool isDebitMessage(String message) => _direction(message) == 'debit';

  static bool isCreditMessage(String message) =>
      _direction(message) == 'credit';

  static String extractMethod(String message) {
    final upperMsg = message.toUpperCase();
    const methodKeywords = [
      'UPI',
      'NEFT',
      'IMPS',
      'RTGS',
      'BANK',
      'ATM',
      'POS',
      'ONLINE',
      'DEBIT CARD',
      'CREDIT CARD',
    ];

    for (final keyword in methodKeywords) {
      if (RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(upperMsg)) {
        return keyword;
      }
    }
    return 'OTHER';
  }

  /// First amount that is not a balance/limit figure.
  static double? extractAmount(String message) {
    for (final match in _amountRe.allMatches(message)) {
      final raw = match.group(1) ?? match.group(2);
      if (raw == null) continue;

      final from = match.start - 25 < 0 ? 0 : match.start - 25;
      final before = message.substring(from, match.start);
      if (_balanceContext.hasMatch(before)) continue;

      final amount = double.tryParse(raw.replaceAll(',', ''));
      if (amount != null && amount > 0) return amount;
    }
    return null;
  }

  static String? extractReference(String message) =>
      _refRe.firstMatch(message)?.group(1);

  static String extractBankName(String sender) {
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
      if (upperSender.contains(pattern)) return bankPatterns[pattern]!;
    }
    return sender;
  }

  static Map<String, dynamic>? parseTransactionSms(
      String sender,
      String message,
      int timestamp,
      ) {
    if (_personalNumber.hasMatch(sender.trim())) {
      debugPrint("🔄 ❌ Ignoring SMS from a personal number");
      return null;
    }
    if (_looksPromotional(sender, message)) {
      debugPrint("🔄 ❌ Promotional / no transaction evidence");
      return null;
    }
    if (_notATransaction.hasMatch(message)) {
      debugPrint("🔄 ❌ Not a completed transaction (OTP/reminder/failed)");
      return null;
    }

    final amount = extractAmount(message);
    if (amount == null) {
      debugPrint("🔄 ❌ No valid amount found");
      return null;
    }

    final direction = _direction(message);
    if (direction == null) {
      debugPrint("🔄 ❌ No debit/credit direction found");
      return null;
    }

    final bankName = extractBankName(sender);
    final method = extractMethod(message);

    final transaction = <String, dynamic>{
      'type': direction,
      'amount': amount,
      'sender': sender,
      'bankName': bankName,
      'message': message,
      'method': method,
      'ref': extractReference(message),
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      'rawTimestamp': timestamp,
    };

    debugPrint("🔄 ✅ TRANSACTION PARSED: $direction ₹$amount "
        "($bankName, $method, ref=${transaction['ref']})");
    return transaction;
  }
}