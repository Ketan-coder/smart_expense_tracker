import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'transactions': 'Transactions',
      'goals': 'Goals',
      'habits': 'Habits',
      'settings': 'Settings',

      // Common
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'save': 'Save',
      'update': 'Update',
      'confirm': 'Confirm',
      'search': 'Search',
      'filter': 'Filter',
      'amount': 'Amount',
      'description': 'Description',
      'date': 'Date',
      'category': 'Category',
      'categories': 'Categories',
      'method': 'Payment Method',
      'total': 'Total',
      'balance': 'Balance',
      'income': 'Income',
      'expense': 'Expense',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      'done': 'Done',

      // Settings
      'appearance': 'Appearance',
      'privacy_security': 'Privacy & Security',
      'integrated_services': 'Integrated Services',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable app notifications',
      'sms_parsing': 'SMS Auto-Parsing',
      'sms_parsing_desc': 'Automatically track expenses from SMS',
      'sms_parsing_disabled': 'Disabled (saves battery)',
      'biometric_auth': 'Biometric Authentication',
      'biometric_enabled': 'Enabled - Lock screen on app start',
      'disabled': 'Disabled',
      'auto_theme': 'Auto Theme',
      'auto_theme_desc': 'Follow system theme settings',
      'dark_mode': 'Dark Mode',
      'dark_mode_desc': 'Use dark theme',
      'dynamic_colors': 'Dynamic Colors',
      'dynamic_colors_desc': 'Use device wallpaper colors',
      'quick_actions': 'Show Quick Actions',
      'quick_actions_desc': 'Quickly add expenses and incomes',
      'privacy_mode': 'Privacy Mode',
      'privacy_mode_active': 'Hide sensitive data with blur/masks',
      'privacy_mode_inactive': 'All data visible',
      'screenshot_protection': 'Screenshot Protection',
      'screenshot_blocked': 'Screenshots and screen recording blocked',
      'screenshot_allowed': 'Screenshots allowed',
      'shake_to_activate': 'Shake to Activate',
      'shake_enabled': 'Shake device or flip face-down to hide data',
      'shake_disabled': 'Gesture activation disabled',
      'adaptive_brightness': 'Adaptive Brightness',
      'adaptive_brightness_active': 'Dims screen when privacy is active',
      'adaptive_brightness_inactive': 'Normal brightness always',
      'gaze_detection': 'Gaze Detection',
      'gaze_detection_active_desc': '⚠️ Camera active - may drain battery (~5%/hr)',
      'gaze_detection_subtitle': 'Disabled (Recommended for battery)',
      'gaze_detection_about' : 'About Gaze Detection',
      'gaze_detection_desc_modal' : 'This feature uses the front camera to detect when multiple people are viewing your screen."',
      'currency': 'Currency',
      'language': 'Language',
      'clear_data': 'Clear All Data',
      'clear_data_desc': 'Delete all expenses, incomes, and settings',

      // Transactions
      'add_transaction': 'Add Transaction',
      'add_expense': 'Add Expense',
      'add_income': 'Add Income',
      'expense_desc': 'Record money spent',
      'income_desc': 'Record money received',
      'payment_method': 'Payment Method',
      'select_categories': 'Select at least one category',

      // Wallets
      'manage_wallets': 'Manage Wallets',
      'add_wallet': 'Add Wallet',
      'edit_wallet': 'Edit Wallet',
      'wallet_name': 'Wallet Name',
      'wallet_type': 'Type',
      'no_wallets': 'No wallets found',
      'delete_wallet': 'Delete Wallet',
      'delete_wallet_confirm': 'Are you sure you want to delete',

      // Recurring Payments
      'manage_recurring': 'Manage Recurring Payments',
      'add_recurring': 'Add New Recurring',
      'edit_recurring': 'Edit Recurring Payment',
      'frequency': 'Frequency',
      'deduction_date': 'Deduction Date',
      'end_date': 'End Date (Optional)',
      'no_end_date': 'No end date',
      'next_deduction': 'Next deduction',
      'status': 'Status',
      'active': 'Active',
      'completed': 'Completed',
      'overdue': 'Overdue',
      'due_soon': 'Due soon',

      // Goals
      'add_goal': 'Create New Goal',
      'goal_name': 'Goal Name',
      'target_amount': 'Target Amount',
      'current_amount': 'Current Amount',
      'deadline': 'Deadline',

      // Habits
      'add_habit': 'Add New Habit',
      'habit_name': 'Habit Name',
      'habit_frequency': 'Frequency',

      // Messages
      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'info': 'Info',
      'expense_added': 'Expense Added',
      'income_added': 'Income Added',
      'category_added': 'Category Added',
      'wallet_added': 'Wallet added',
      'wallet_updated': 'Wallet updated',
      'wallet_deleted': 'Wallet deleted',
      'recurring_added': 'Recurring payment added',
      'recurring_updated': 'Recurring payment updated',
      'recurring_deleted': 'Recurring payment deleted',
      'fill_all_fields': 'Please fill all fields',
      'select_category': 'Please select at least one category',
      'privacy_enabled': 'Privacy Mode enabled',
      'privacy_disabled': 'Privacy Mode disabled',
      'screenshot_protection_enabled': 'Screenshot protection enabled',
      'screenshot_protection_disabled': 'Screenshot protection disabled',
      'data_cleared': 'All data cleared successfully',
      'notifications_enabled': 'Notifications enabled',
      'notifications_disabled': 'Notifications disabled',
      'language_changed': 'Language changed to',
      'restarting': 'Restarting...',
      'app_restart_required': 'The app needs to restart to apply changes.',

      // Dialogs
      'change_currency_title': 'Change Currency?',
      'change_currency_msg': 'Changing currency to',
      'change_language_title': 'Change Language?',
      'change_language_msg': 'Changing language to',
      'enable_notifications_title': 'Enable Notifications?',
      'disable_notifications_title': 'Disable Notifications?',
      'disable_notifications_msg': 'You will not receive any notifications. The app needs to restart.',
      'enable': 'Enable',
      'disable': 'Disable',
      'change': 'Change',

      // Frequencies
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',

      // Wallet Types
      'cash': 'Cash',
      'bank': 'Bank',
      'card': 'Card',
      'upi': 'UPI',
      'credit': 'Credit Card',
      'other': 'Other',
    },
    'hi': {
      // Navigation (already complete)
      'home': 'होम',
      'transactions': 'लेनदेन',
      'goals': 'लक्ष्य',
      'habits': 'आदतें',
      'settings': 'सेटिंग्स',

      // Common (already complete)
      'add': 'जोड़ें',
      'edit': 'संपादित करें',
      'delete': 'हटाएं',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'update': 'अपडेट करें',
      'confirm': 'पुष्टि करें',
      'search': 'खोजें',
      'filter': 'फ़िल्टर',
      'amount': 'राशि',
      'description': 'विवरण',
      'date': 'तारीख',
      'category': 'श्रेणी',
      'categories': 'श्रेणियाँ',
      'method': 'भुगतान विधि',
      'total': 'कुल',
      'balance': 'शेष',
      'income': 'आय',
      'expense': 'खर्च',
      'yes': 'हाँ',
      'no': 'नहीं',
      'close': 'बंद करें',
      'done': 'हो गया',

      // Settings
      'appearance': 'रूप',
      'privacy_security': 'गोपनीयता और सुरक्षा',
      'integrated_services': 'एकीकृत सेवाएं',
      'notifications': 'सूचनाएं',
      'enable_notifications': 'ऐप सूचनाएं सक्षम करें',
      'sms_parsing': 'SMS ऑटो-पार्सिंग',
      'sms_parsing_desc': 'SMS से स्वचालित रूप से खर्च ट्रैक करें',
      'sms_parsing_disabled': 'अक्षम (बैटरी बचाता है)',
      'biometric_auth': 'बायोमेट्रिक प्रमाणीकरण',
      'biometric_enabled': 'सक्षम - ऐप शुरू होने पर लॉक स्क्रीन',
      'disabled': 'अक्षम',
      'auto_theme': 'ऑटो थीम',
      'auto_theme_desc': 'सिस्टम थीम सेटिंग्स का पालन करें',
      'dark_mode': 'डार्क मोड',
      'dark_mode_desc': 'डार्क थीम का उपयोग करें',
      'dynamic_colors': 'डायनामिक रंग',
      'dynamic_colors_desc': 'डिवाइस वॉलपेपर रंगों का उपयोग करें',
      'quick_actions': 'त्वरित क्रियाएं दिखाएं',
      'quick_actions_desc': 'खर्च और आय जल्दी जोड़ें',
      'privacy_mode': 'गोपनीयता मोड',
      'privacy_mode_active': 'संवेदनशील डेटा को धुंधला/मास्क के साथ छिपाएं',
      'privacy_mode_inactive': 'सभी डेटा दृश्यमान',
      'screenshot_protection': 'स्क्रीनशॉट सुरक्षा',
      'screenshot_blocked': 'स्क्रीनशॉट और स्क्रीन रिकॉर्डिंग अवरुद्ध',
      'screenshot_allowed': 'स्क्रीनशॉट की अनुमति',
      'shake_to_activate': 'सक्रिय करने के लिए हिलाएं',
      'shake_enabled': 'डिवाइस को हिलाएं या डेटा छिपाने के लिए उल्टा करें',
      'shake_disabled': 'जेस्चर सक्रियण अक्षम',
      'adaptive_brightness': 'अनुकूली चमक',
      'adaptive_brightness_active': 'गोपनीयता सक्रिय होने पर स्क्रीन मंद करता है',
      'adaptive_brightness_inactive': 'हमेशा सामान्य चमक',
      'gaze_detection': 'दृष्टि पहचान',
      'gaze_detection_active_desc': '⚠️ कैमरा सक्रिय - बैटरी खपत हो सकती है (~5%/घंटा)',
      'gaze_detection_subtitle': 'अक्षम (बैटरी के लिए अनुशंसित)',
      'gaze_detection_about': 'दृष्टि पहचान के बारे में',
      'gaze_detection_desc_modal': 'यह सुविधा फ्रंट कैमरे का उपयोग करती है जब कई लोग आपकी स्क्रीन देख रहे हों तो पता लगाने के लिए।',
      'currency': 'मुद्रा',
      'language': 'भाषा',
      'clear_data': 'सभी डेटा साफ़ करें',
      'clear_data_desc': 'सभी खर्च, आय और सेटिंग्स हटाएं',

      // Transactions
      'add_transaction': 'लेनदेन जोड़ें',
      'add_expense': 'खर्च जोड़ें',
      'add_income': 'आय जोड़ें',
      'expense_desc': 'खर्च किए गए पैसे रिकॉर्ड करें',
      'income_desc': 'प्राप्त पैसे रिकॉर्ड करें',
      'payment_method': 'भुगतान विधि',
      'select_categories': 'कम से कम एक श्रेणी चुनें',

      // Wallets
      'manage_wallets': 'वॉलेट प्रबंधित करें',
      'add_wallet': 'वॉलेट जोड़ें',
      'edit_wallet': 'वॉलेट संपादित करें',
      'wallet_name': 'वॉलेट नाम',
      'wallet_type': 'प्रकार',
      'no_wallets': 'कोई वॉलेट नहीं मिला',
      'delete_wallet': 'वॉलेट हटाएं',
      'delete_wallet_confirm': 'क्या आप वाकई हटाना चाहते हैं',

      // Recurring Payments
      'manage_recurring': 'आवर्ती भुगतान प्रबंधित करें',
      'add_recurring': 'नया आवर्ती जोड़ें',
      'edit_recurring': 'आवर्ती भुगतान संपादित करें',
      'frequency': 'आवृत्ति',
      'deduction_date': 'कटौती तिथि',
      'end_date': 'समाप्ति तिथि (वैकल्पिक)',
      'no_end_date': 'कोई समाप्ति तिथि नहीं',
      'next_deduction': 'अगली कटौती',
      'status': 'स्थिति',
      'active': 'सक्रिय',
      'completed': 'पूर्ण',
      'overdue': 'अतिदेय',
      'due_soon': 'जल्द ही देय',

      // Goals
      'add_goal': 'नया लक्ष्य बनाएं',
      'goal_name': 'लक्ष्य नाम',
      'target_amount': 'लक्ष्य राशि',
      'current_amount': 'वर्तमान राशि',
      'deadline': 'समय सीमा',

      // Habits
      'add_habit': 'नई आदत जोड़ें',
      'habit_name': 'आदत नाम',
      'habit_frequency': 'आवृत्ति',

      // Messages
      'success': 'सफलता',
      'error': 'त्रुटि',
      'warning': 'चेतावनी',
      'info': 'जानकारी',
      'expense_added': 'खर्च जोड़ा गया',
      'income_added': 'आय जोड़ी गई',
      'category_added': 'श्रेणी जोड़ी गई',
      'wallet_added': 'वॉलेट जोड़ा गया',
      'wallet_updated': 'वॉलेट अपडेट किया गया',
      'wallet_deleted': 'वॉलेट हटाया गया',
      'recurring_added': 'आवर्ती भुगतान जोड़ा गया',
      'recurring_updated': 'आवर्ती भुगतान अपडेट किया गया',
      'recurring_deleted': 'आवर्ती भुगतान हटाया गया',
      'fill_all_fields': 'कृपया सभी फ़ील्ड भरें',
      'select_category': 'कृपया कम से कम एक श्रेणी चुनें',
      'privacy_enabled': 'गोपनीयता मोड सक्षम',
      'privacy_disabled': 'गोपनीयता मोड अक्षम',
      'screenshot_protection_enabled': 'स्क्रीनशॉट सुरक्षा सक्षम',
      'screenshot_protection_disabled': 'स्क्रीनशॉट सुरक्षा अक्षम',
      'data_cleared': 'सभी डेटा सफलतापूर्वक साफ़ किया गया',
      'notifications_enabled': 'सूचनाएं सक्षम',
      'notifications_disabled': 'सूचनाएं अक्षम',
      'language_changed': 'भाषा बदली गई',
      'restarting': 'पुनः प्रारंभ हो रहा है...',
      'app_restart_required': 'परिवर्तन लागू करने के लिए ऐप को पुनः प्रारंभ करना होगा।',

      // Dialogs
      'change_currency_title': 'मुद्रा बदलें?',
      'change_currency_msg': 'मुद्रा बदलना',
      'change_language_title': 'भाषा बदलें?',
      'change_language_msg': 'भाषा बदलना',
      'enable_notifications_title': 'सूचनाएं सक्षम करें?',
      'disable_notifications_title': 'सूचनाएं अक्षम करें?',
      'disable_notifications_msg': 'आपको कोई सूचना नहीं मिलेगी। ऐप को पुनः प्रारंभ करना होगा।',
      'enable': 'सक्षम करें',
      'disable': 'अक्षम करें',
      'change': 'बदलें',

      // Frequencies
      'daily': 'दैनिक',
      'weekly': 'साप्ताहिक',
      'monthly': 'मासिक',
      'yearly': 'वार्षिक',

      // Wallet Types
      'cash': 'नकद',
      'bank': 'बैंक',
      'card': 'कार्ड',
      'upi': 'UPI',
      'credit': 'क्रेडिट कार्ड',
      'other': 'अन्य',
    },
    // Add more languages as needed (ta, te, kn, ml, bn, gu, mr, pa)
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get home => translate('home');
  String get transactions => translate('transactions');
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
// Add getters for all frequently used strings
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'ta', 'te', 'kn', 'ml', 'bn', 'gu', 'mr', 'pa'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}