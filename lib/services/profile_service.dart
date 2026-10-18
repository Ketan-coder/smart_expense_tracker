import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../core/profile_scope.dart';
import '../data/model/category.dart';
import '../data/model/daily_progress.dart';
import '../data/model/expense.dart';
import '../data/model/goal.dart';
import '../data/model/habit.dart';
import '../data/model/income.dart';
import '../data/model/loan.dart';
import '../data/model/recurring.dart';
import '../data/model/wallet.dart';

class FinancialProfile {
  const FinancialProfile({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String id;
  final String name;
  final String currencyCode;
  final String currencySymbol;

  FinancialProfile copyWith({
    String? name,
    String? currencyCode,
    String? currencySymbol,
  }) => FinancialProfile(
    id: id,
    name: name ?? this.name,
    currencyCode: currencyCode ?? this.currencyCode,
    currencySymbol: currencySymbol ?? this.currencySymbol,
  );

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'currencyCode': currencyCode,
    'currencySymbol': currencySymbol,
  };

  factory FinancialProfile.fromJson(Map<String, dynamic> json) =>
      FinancialProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        currencyCode: json['currencyCode'] as String? ?? 'INR',
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
      );
}

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();
  static const _profilesKey = 'financial_profiles';
  static const _activeProfileKey = 'active_financial_profile';
  static const _legacyMigratedKey = 'legacy_financial_data_migrated';

  final ValueNotifier<String> activeProfileNotifier = ValueNotifier<String>(
    'default',
  );
  List<FinancialProfile> _profiles = const [];

  List<FinancialProfile> get profiles => List.unmodifiable(_profiles);
  String get activeProfileId => ProfileScope.activeProfileId;
  FinancialProfile profileById(String profileId) => _profiles.firstWhere(
    (profile) => profile.id == profileId,
    orElse: () =>
        throw ArgumentError.value(profileId, 'profileId', 'Unknown profile'),
  );
  FinancialProfile get activeProfile => _profiles.firstWhere(
    (profile) => profile.id == activeProfileId,
    orElse: () => _profiles.first,
  );

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProfiles = prefs.getString(_profilesKey);
    if (savedProfiles == null) {
      final symbol = prefs.getString('selectedCurrency') ?? '₹';
      final legacyProfile = FinancialProfile(
        id: 'default',
        name: 'My Profile',
        currencyCode: _currencyCodeForSymbol(symbol),
        currencySymbol: symbol,
      );
      _profiles = [legacyProfile];
      await _saveProfiles(prefs);
    } else {
      final decoded = jsonDecode(savedProfiles) as List<dynamic>;
      _profiles = decoded
          .map(
            (entry) => FinancialProfile.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
      if (_profiles.isEmpty) {
        _profiles = const [
          FinancialProfile(
            id: 'default',
            name: 'My Profile',
            currencyCode: 'INR',
            currencySymbol: '₹',
          ),
        ];
      }
    }

    final requestedId = prefs.getString(_activeProfileKey);
    final active = _profiles.any((profile) => profile.id == requestedId)
        ? requestedId!
        : _profiles.first.id;
    ProfileScope.activeProfileId = active;
    activeProfileNotifier.value = active;

    final migrated = prefs.getBool(_legacyMigratedKey) ?? false;
    await _openProfileBoxes(active, migrateLegacy: !migrated);
    if (!migrated) {
      await prefs.setBool(_legacyMigratedKey, true);
    }
    await prefs.setString(_activeProfileKey, active);
  }

  Future<FinancialProfile> createProfile({
    required String name,
    required String currencyCode,
    required String currencySymbol,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty');
    }
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    final profile = FinancialProfile(
      id: id,
      name: cleanedName,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
    _profiles = [..._profiles, profile];
    await _saveProfiles(await SharedPreferences.getInstance());
    await _openProfileBoxes(id);
    await switchProfile(id);
    return profile;
  }

  Future<void> switchProfile(String profileId) async {
    if (!_profiles.any((profile) => profile.id == profileId)) {
      throw ArgumentError.value(profileId, 'profileId', 'Unknown profile');
    }
    await _openProfileBoxes(profileId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileKey, profileId);
    ProfileScope.activeProfileId = profileId;
    activeProfileNotifier.value = profileId;
  }

  Future<void> updateCurrency({
    required String profileId,
    required String currencyCode,
    required String currencySymbol,
  }) async {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index < 0) {
      throw ArgumentError.value(profileId, 'profileId', 'Unknown profile');
    }
    final updated = _profiles[index].copyWith(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
    _profiles = [..._profiles]..[index] = updated;
    await _saveProfiles(await SharedPreferences.getInstance());
  }

  Future<void> _saveProfiles(SharedPreferences prefs) async {
    await prefs.setString(
      _profilesKey,
      jsonEncode(_profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  String _currencyCodeForSymbol(String symbol) => switch (symbol) {
    '€' => 'EUR',
    r'$' => 'USD',
    '£' => 'GBP',
    '¥' => 'JPY',
    _ => 'INR',
  };

  Future<void> _openProfileBoxes(
    String profileId, {
    bool migrateLegacy = false,
  }) async {
    await _openProfileBox<Expense>('expenses', profileId);
    await _openProfileBox<Income>('incomes', profileId);
    await _openProfileBox<Wallet>('wallets', profileId);
    await _openProfileBox<Category>('categories', profileId);
    await _openProfileBox<Goal>('goals', profileId);
    await _openProfileBox<Habit>('habits', profileId);
    await _openProfileBox<Recurring>('recurrings', profileId);
    await _openProfileBox<Loan>('loans', profileId);
    await _openProfileBox<DailyProgress>('daily_progress', profileId);
    if (migrateLegacy && profileId == 'default') {
      await _classifyLegacyLinkedTransactions();
    }
  }

  Future<void> _classifyLegacyLinkedTransactions() async {
    final loans = Hive.box<Loan>(AppConstants.loans);
    final expenses = Hive.box<Expense>(AppConstants.expenses);
    final incomes = Hive.box<Income>(AppConstants.incomes);
    final wallets = Hive.box<Wallet>(AppConstants.wallets);

    for (final key in expenses.keys.whereType<int>()) {
      final expense = expenses.get(key);
      if (expense != null && expense.walletKey == null) {
        final walletKey = _legacyWalletKey(wallets, expense.method);
        if (walletKey != null) {
          expense.walletKey = walletKey;
          expense.balanceApplied = true;
          await expenses.put(key, expense);
        }
      }
    }
    for (final key in incomes.keys.whereType<int>()) {
      final income = incomes.get(key);
      if (income != null && income.walletKey == null) {
        final walletKey = _legacyWalletKey(wallets, income.method);
        if (walletKey != null) {
          income.walletKey = walletKey;
          income.balanceApplied = true;
          await incomes.put(key, income);
        }
      }
    }

    for (final loan in loans.values) {
      final paymentIds = loan.payments
          .map((payment) => payment.transactionId)
          .toSet();
      for (final transactionId in loan.linkedTransactionIds) {
        final key = int.tryParse(transactionId);
        if (key == null) continue;
        final isPayment = paymentIds.contains(transactionId);

        if (loan.type == LoanType.lent) {
          if (isPayment) {
            final income = incomes.get(key);
            if (income != null) {
              income.classification = 'loan_repayment';
              income.recognizedAmount = loan.payments
                  .firstWhere(
                    (payment) => payment.transactionId == transactionId,
                  )
                  .interestPaid;
              await incomes.put(key, income);
            }
          } else {
            final expense = expenses.get(key);
            if (expense != null) {
              expense.classification = 'loan_lent';
              expense.recognizedAmount = 0;
              await expenses.put(key, expense);
            }
          }
        } else if (isPayment) {
          final payment = loan.payments.firstWhere(
            (candidate) => candidate.transactionId == transactionId,
          );
          final expense = expenses.get(key);
          if (expense != null) {
            expense.classification = 'loan_repayment';
            expense.recognizedAmount = payment.interestPaid;
            await expenses.put(key, expense);
          }
        } else {
          final income = incomes.get(key);
          if (income != null) {
            income.classification = 'loan_proceeds';
            income.recognizedAmount = 0;
            await incomes.put(key, income);
          }
        }
      }
    }

    for (final key in incomes.keys.whereType<int>().toList()) {
      final income = incomes.get(key);
      if (income == null) continue;
      if (income.description.startsWith('Goal Installment:')) {
        final walletKey = income.walletKey;
        final wallet = walletKey == null ? null : wallets.get(walletKey);
        if (wallet != null && income.balanceApplied != false) {
          wallet.balance -= income.amount;
          await wallet.save();
        }
        income.classification = 'goal_allocation';
        income.recognizedAmount = 0;
        income.balanceApplied = false;
        await incomes.put(key, income);
      }
    }
    for (final wallet in wallets.values) {
      wallet.balanceAsOf ??= DateTime.now();
      await wallet.save();
    }
  }

  int? _legacyWalletKey(Box<Wallet> wallets, String? method) {
    final normalized = method?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final key in wallets.keys.whereType<int>()) {
      final wallet = wallets.get(key);
      if (wallet?.type.trim().toLowerCase() == normalized) return key;
    }
    return null;
  }

  Future<void> _openProfileBox<T>(String legacyName, String profileId) async {
    final boxName = profileId == 'default'
        ? legacyName
        : '${legacyName}__profile_$profileId';
    await Hive.openBox<T>(boxName);
  }

  static Future<void> openActiveProfileBoxes() async {
    await instance._openProfileBoxes(ProfileScope.activeProfileId);
  }
}
