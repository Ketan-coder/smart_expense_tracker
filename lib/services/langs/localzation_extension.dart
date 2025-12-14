import 'package:flutter/material.dart';

import 'app_localalizations.dart';


extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;

  // Quick access methods
  String t(String key) => loc.translate(key);
}

// Usage example:
// Text(context.loc.home)
// Text(context.t('custom_key'))