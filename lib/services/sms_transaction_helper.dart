import 'dart:async';

import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/core/helpers.dart';
import 'package:expense_tracker/data/local/universal_functions.dart';
import 'package:expense_tracker/data/model/category.dart';
import 'package:expense_tracker/screens/widgets/transaction_sheet.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/notification_helper.dart';
import 'package:expense_tracker/services/sms_service.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns SMS -> transaction handling for the whole app lifetime.
///
/// Registered once from main(), so it does not depend on any screen, the
/// biometric lock, permission sheets, or SmsListener.initialize() succeeding.
///
/// Three layers keep capture close to 100%:
///  1. live delivery from the native receiver,
///  2. replay of the native durable queue (start + every resume),
///  3. inbox reconciliation (start + every resume) for anything the OS never
///     delivered to the receiver.
/// A persistent de-duplication store makes all three safe to overlap.
class SmsTransactionHandler {
  SmsTransactionHandler._();

  static bool _started = false;
  static final _LifecycleHook _hook = _LifecycleHook();

  static const String _kProcessed = 'sms_processed_keys';
  static const String _kLastSync = 'sms_last_inbox_sync';
  static const String _kBaseline = 'sms_sync_baseline';
  static const int _maxKeys = 600;
  static const int _bucketMs = 5 * 60 * 1000;
  static const int _syncSlackMs = 10 * 60 * 1000;
  static const int _maxLookbackMs = 30 * 24 * 60 * 60 * 1000;

  static final List<String> _keys = <String>[];
  static final Set<String> _keySet = <String>{};
  static bool _keysLoaded = false;
  static bool _syncing = false;

  static void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_hook);
    SmsListener.startListening(handle); // also drains the native queue
    unawaited(syncMissed());
    debugPrint("📨 SmsTransactionHandler registered");
  }

  /// Called on every app resume.
  static Future<void> catchUp() async {
    await SmsListener.drainPendingMessages();
    await syncMissed();
  }

  // ---------------------------------------------------------------------
  // Handling one SMS
  // ---------------------------------------------------------------------

  static Future<void> handle(
    String sender,
    String message,
    int timestamp,
  ) async {
    final transaction = SmsListener.parseTransactionSms(
      sender,
      message,
      timestamp,
    );
    if (transaction == null) return;

    await _loadKeys();
    final dedupe = _dedupeKeys(transaction, sender, message, timestamp);
    if (dedupe.check.any(_keySet.contains)) {
      debugPrint("📨 ↩️ Duplicate SMS ignored");
      return;
    }
    _claim(dedupe.store); // synchronous: concurrent callers see it at once

    final double amount =
        double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final String bankName = transaction['bankName'] ?? sender;
    final String description = 'Auto: $bankName';
    final String method = transaction['method'] ?? 'UPI';
    final DateTime date = transaction['timestamp'] as DateTime;
    final bool isCredit = transaction['type'] == 'credit';

    bool success = false;
    try {
      if (isCredit) {
        success = await UniversalHiveFunctions().addIncome(
          amount: amount,
          description: description,
          method: method,
          categoryKeys: await _defaultCategoryKeys(isIncome: true),
          allowUnassigned: true,
          date: date,
        );
      } else {
        success = await UniversalHiveFunctions().addExpense(
          amount: amount,
          description: description,
          method: method,
          categoryKeys: await _defaultCategoryKeys(isIncome: false),
          allowUnassigned: true,
          date: date,
        );
      }
    } catch (e) {
      _release(dedupe.store);
      rethrow;
    }

    if (!success) {
      _release(dedupe.store);
      debugPrint("📨 ❌ Failed to save transaction");
      // Throwing keeps the SMS in the native queue for the next drain.
      throw StateError('SMS transaction could not be saved');
    }

    unawaited(_persistKeys());
    debugPrint(
      "📨 ✅ Transaction saved: ${isCredit ? 'income' : 'expense'} "
      "$amount",
    );

    // Confirmation sheet only for fresh SMS; replays/inbox catch-up are silent.
    final isFresh =
        DateTime.now().millisecondsSinceEpoch - timestamp < 2 * 60 * 1000;
    if (isFresh) {
      final currency = await Helpers().getCurrentCurrency() ?? '₹';
      await NotificationHelper.notifySmsTransactionLogged(
        amount: amount,
        type: isCredit ? 'Income' : 'Expense',
        description: description,
        currency: currency,
        dedupeKey: dedupe.store,
      );
    }
    if (!isFresh) return;

    final ctx = NotificationService.navigatorKey.currentState?.overlay?.context;
    if (ctx != null && ctx.mounted) {
      final currency = await Helpers().getCurrentCurrency() ?? 'INR';
      if (ctx.mounted) {
        TransactionSheet.show(
          context: ctx,
          isIncome: isCredit,
          amount: amount,
          currency: currency,
          description: description,
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Inbox reconciliation
  // ---------------------------------------------------------------------

  static Future<void> syncMissed() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Don't import messages from a period when parsing was switched off.
      final enabled = await Helpers().getCurrentSmsParsingState() ?? true;
      if (!enabled) {
        await prefs.setInt(_kLastSync, now);
        await prefs.setInt(_kBaseline, now);
        return;
      }

      final last = prefs.getInt(_kLastSync);
      if (last == null) {
        // First run: baseline only, never import old history.
        await prefs.setInt(_kLastSync, now);
        await prefs.setInt(_kBaseline, now);
        return;
      }

      // The slack window may reach back before the first-run baseline, which
      // would re-import SMS from before this install/reset. Never go below it.
      var baseline = prefs.getInt(_kBaseline);
      if (baseline == null) {
        baseline = last;
        await prefs.setInt(_kBaseline, baseline);
      }

      var since = last - _syncSlackMs;
      if (since < baseline) since = baseline;
      if (since < now - _maxLookbackMs) since = now - _maxLookbackMs;

      final rows = await SmsListener.readInboxSince(since);
      if (rows == null) return; // couldn't read; try again next time

      var allOk = true;
      for (final row in rows) {
        try {
          await handle(
            row['sender']?.toString() ?? '',
            row['message']?.toString() ?? '',
            (row['timestamp'] as num?)?.toInt() ?? now,
          );
        } catch (e) {
          allOk = false;
          debugPrint("📨 ⚠️ Inbox item failed: $e");
        }
      }

      if (allOk) await prefs.setInt(_kLastSync, now);
      if (rows.isNotEmpty) {
        debugPrint("📨 Inbox sync checked ${rows.length} SMS");
      }
    } catch (e) {
      debugPrint("📨 ⚠️ Inbox sync failed: $e");
    } finally {
      _syncing = false;
    }
  }

  // ---------------------------------------------------------------------
  // De-duplication store
  // ---------------------------------------------------------------------

  static ({String store, List<String> check}) _dedupeKeys(
    Map<String, dynamic> transaction,
    String sender,
    String message,
    int timestamp,
  ) {
    final ref = transaction['ref'] as String?;
    if (ref != null) {
      final k = 'ref:$ref:${transaction['type']}:${transaction['amount']}';
      return (store: k, check: [k]);
    }
    final h = '${_fnv('${sender.toLowerCase()}|$message')}';
    final bucket = timestamp ~/ _bucketMs;
    return (
      store: 'h:$h:$bucket',
      check: ['h:$h:${bucket - 1}', 'h:$h:$bucket', 'h:$h:${bucket + 1}'],
    );
  }

  static int _fnv(String s) {
    var h = 0x811c9dc5;
    for (final u in s.codeUnits) {
      h ^= u;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  static Future<void> _loadKeys() async {
    if (_keysLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    if (_keysLoaded) return;
    final saved = prefs.getStringList(_kProcessed) ?? <String>[];
    _keys.addAll(saved);
    _keySet.addAll(saved);
    _keysLoaded = true;
  }

  static void _claim(String key) {
    _keys.add(key);
    _keySet.add(key);
    while (_keys.length > _maxKeys) {
      _keySet.remove(_keys.removeAt(0));
    }
  }

  static void _release(String key) {
    _keys.remove(key);
    _keySet.remove(key);
  }

  static Future<void> _persistKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kProcessed, List<String>.from(_keys));
    } catch (e) {
      debugPrint("📨 ⚠️ Could not persist dedupe keys: $e");
    }
  }

  // ---------------------------------------------------------------------
  // Default categories (same behaviour as the old BottomNavBar code)
  // ---------------------------------------------------------------------

  static Future<List<int>> _defaultCategoryKeys({
    required bool isIncome,
  }) async {
    final fallback = isIncome ? 7 : 14;
    final defaults = isIncome
        ? await Helpers().getDefaultIncomeCategory() ?? []
        : await Helpers().getDefaultExpenseCategory() ?? [];
    if (defaults.isEmpty) return [fallback];

    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final values = categoryBox.values.toList();
    final keys = <int>[];

    for (final name in defaults) {
      final index = values.indexWhere((cat) => cat.name == name);
      if (index == -1) continue;
      final key = categoryBox.keyAt(index);
      if (key != null) keys.add(key as int);
    }

    return keys.isNotEmpty ? keys : [fallback];
  }
}

class _LifecycleHook with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SmsTransactionHandler.catchUp());
    }
  }
}
