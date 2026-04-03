import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _translations;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  Future<void> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/langs/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _translations = jsonMap.map((k, v) => MapEntry(k, v.toString()));
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  String get tryAgain => translate('try_again');
  String get exit => translate('exit');
  String get home => translate('home');
  String get transactions => translate('transactions');
  String get income => translate('income');
  String get expense => translate('expense');
  String get savings => translate('savings');
  String get recurring => translate('recurring');
  String get recent => translate('recent');
  String get see_all => translate('see_all');
  String get goals => translate('goals');
  String get habits => translate('habits');
  String get settings => translate('settings');
  String get add => translate('add');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get update => translate('update');
  String get amount => translate('amount');
  String get description => translate('description');
  String get category => translate('category');
  String get categories => translate('categories');
  String get currency => translate('currency');
  String get language => translate('language');
  String get addExpense => translate('add_expense');
  String get addIncome => translate('add_income');
  String get manageWallets => translate('manage_wallets');
  String get manageRecurring => translate('manage_recurring');
  String get paymentMethod => translate('payment_method');
  String get notifications => translate('notifications');
  String get smsParsing => translate('sms_parsing');
  String get biometricAuth => translate('biometric_auth');
  String get darkMode => translate('dark_mode');
  String get privacyMode => translate('privacy_mode');
  String get clearData => translate('clear_data');
  String get select => translate('select');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
    'en', 'hi', 'ta', 'te', 'kn', 'ml', 'bn', 'gu', 'mr', 'pa'
  ].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load(); // loads from JSON
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}