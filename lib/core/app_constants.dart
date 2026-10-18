import 'profile_scope.dart';

class AppConstants {
  static String get expenses => ProfileScope.boxName('expenses');
  static String get incomes => ProfileScope.boxName('incomes');
  static String get habits => ProfileScope.boxName('habits');
  static String get categories => ProfileScope.boxName('categories');
  static String get recurrings => ProfileScope.boxName('recurrings');
  static String get wallets => ProfileScope.boxName('wallets');
  static String get goals => ProfileScope.boxName('goals');
  static String get loans => ProfileScope.boxName('loans');
  static String get dailyProgress => ProfileScope.boxName('daily_progress');

  static const loanDocuments = 'loan_documents'; // typeId: 13
  static const loanCreditorTypes = 'loan_creditor_types'; // typeId: 14
  static const interestTypes = 'interest_types'; // typeId: 15
  static const paymentFrequencies = 'payment_frequencies'; // typeId: 16
  static const loanPurposes = 'loan_purposes'; // typeId: 17
  static const documentTypes = 'document_types'; // typeId: 18

  // ---------------- Icon ----------------------------
  static const String successSendLottieJsonPath =
      'assets/icons/SuccessSendLottie.json';
  static const String cellphoneJsonPath = 'assets/icons/Cellphone.json';
  static const String spinningIndianRupeeCoin =
      'assets/icons/IndiaRupeeCoin.json';
  static const String moneyRainDashboardJsonPath =
      'assets/icons/MoneyRainDashboard.json';
}
