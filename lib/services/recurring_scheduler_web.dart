// Web stub for recurring scheduler
// This file is used when running on web platform

import 'package:flutter/foundation.dart';

Future<void> registerRecurringTask() async {
  debugPrint('⚠️ Recurring task scheduler not available on web platform');
  // No-op for web
  return Future.value();
}

// Add any other functions from your recurring_scheduler.dart that need web stubs
void cancelRecurringTask() {
  debugPrint('⚠️ Cancel recurring task not available on web platform');
}