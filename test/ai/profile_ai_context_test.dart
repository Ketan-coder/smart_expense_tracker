import 'dart:io';

import 'package:expense_tracker/ai/ai_provider.dart';
import 'package:expense_tracker/ai/chat_history_store.dart';
import 'package:expense_tracker/ai/context_builder.dart';
import 'package:expense_tracker/ai/memory_store.dart';
import 'package:expense_tracker/core/profile_scope.dart';
import 'package:expense_tracker/data/model/expense.dart';
import 'package:expense_tracker/data/model/income.dart';
import 'package:expense_tracker/data/model/wallet.dart';
import 'package:expense_tracker/hive_registrar.g.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late FinancialProfile euroProfile;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDirectory = await Directory.systemTemp.createTemp(
      'profile_ai_context_test',
    );
    Hive.init(hiveDirectory.path);
    Hive.registerAdapters();
    await ProfileService.instance.initialize();
    euroProfile = await ProfileService.instance.createProfile(
      name: 'Europe',
      currencyCode: 'EUR',
      currencySymbol: '€',
    );
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'AI context separates wallet balance from reportable spending',
    () async {
      final now = DateTime.now();
      await Hive.box<Wallet>('wallets').put(
        1,
        Wallet(name: 'Main bank', balance: 35000, type: 'bank', createdAt: now),
      );
      await Hive.box<Expense>('expenses').put(
        1,
        Expense(
          amount: 9438,
          date: now,
          description: 'Groceries',
          categoryKeys: const [],
        ),
      );

      await ProfileService.instance.switchProfile(euroProfile.id);
      await Hive.box<Wallet>('wallets__profile_${euroProfile.id}').put(
        1,
        Wallet(name: 'Euro wallet', balance: 250, type: 'bank', createdAt: now),
      );
      await Hive.box<Expense>('expenses__profile_${euroProfile.id}').put(
        1,
        Expense(
          amount: 12,
          date: now,
          description: 'Lunch in Europe',
          categoryKeys: const [],
        ),
      );
      await Hive.box<Income>('incomes__profile_${euroProfile.id}').put(
        1,
        Income(
          amount: 50,
          date: now,
          description: 'Freelance',
          categoryKeys: const [],
        ),
      );

      final euroContext = await ContextBuilder(
        profileId: euroProfile.id,
      ).buildFullContext();
      expect(euroContext, contains('Currency: EUR (€)'));
      expect(euroContext, contains('€12'));
      expect(euroContext, contains('Current total wallet balance: €250'));
      expect(euroContext, contains('AVAILABLE BALANCES (NOT SPENDING)'));
      expect(euroContext, isNot(contains('Main bank')));
      expect(euroContext, isNot(contains('₹')));

      ProfileScope.activeProfileId = 'default';
      final defaultContext = await ContextBuilder(
        profileId: 'default',
      ).buildFullContext();
      expect(defaultContext, contains('₹9.4K'));
      expect(defaultContext, contains('Current total wallet balance: ₹35.0K'));
      expect(defaultContext, isNot(contains('Lunch in Europe')));
    },
  );

  test('AI chat history and memories are isolated by profile', () async {
    final firstMessage = AiMessage(
      content: 'India-only conversation',
      isUser: true,
      timestamp: DateTime.now(),
    );
    final defaultHistory = ChatHistoryStore(profileId: 'default');
    await defaultHistory.save([firstMessage]);
    await defaultHistory.saveSummary('India profile conversation summary');

    final euroHistory = ChatHistoryStore(profileId: euroProfile.id);
    expect(await euroHistory.load(), isEmpty);
    expect(await euroHistory.loadSummary(), isEmpty);
    await euroHistory.save([
      AiMessage(
        content: 'Euro-only conversation',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ]);
    await euroHistory.saveSummary('Europe profile conversation summary');
    expect((await defaultHistory.load()).single.content, firstMessage.content);
    expect(
      await defaultHistory.loadSummary(),
      'India profile conversation summary',
    );
    expect(
      await euroHistory.loadSummary(),
      'Europe profile conversation summary',
    );

    final defaultMemories = MemoryStore(profileId: 'default');
    await defaultMemories.upsertMemory(
      key: 'home_currency',
      fact: 'Tracks finances in INR',
      type: MemoryType.preference,
      confidence: 1,
      importance: 1,
    );
    final euroMemories = MemoryStore(profileId: euroProfile.id);
    expect(await euroMemories.load(), isEmpty);
    await euroMemories.upsertMemory(
      key: 'home_currency',
      fact: 'Tracks finances in EUR',
      type: MemoryType.preference,
      confidence: 1,
      importance: 1,
    );
    expect(
      (await defaultMemories.load()).single.fact,
      'Tracks finances in INR',
    );
  });
}
