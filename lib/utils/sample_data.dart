import 'package:drift/drift.dart';
import '../data/database.dart';

class SampleDataGenerator {
  static Future<void> generateSampleData(AppDatabase database) async {
    try {
      // Check if there's already data
      final existingAccounts = await database.getAllAccounts();
      if (existingAccounts.isNotEmpty) {
        print('Sample data already exists');
        return;
      }

      // Get account groups
      final groups = await database.getAllAccountGroups();
      if (groups.isEmpty) {
        print('No account groups found');
        return;
      }

      // Find specific groups
      final assetsGroup = groups.firstWhere((g) => g.name == 'Assets');
      final expensesGroup = groups.firstWhere((g) => g.name == 'Expenses');
      final revenueGroup = groups.firstWhere((g) => g.name == 'Revenue');

      // Create sample accounts
      final cashAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Cash'),
        groupId: Value(assetsGroup.id),
      ));

      final revenueAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Service Revenue'),
        groupId: Value(revenueGroup.id),
      ));

      final expenseAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Office Supplies'),
        groupId: Value(expensesGroup.id),
      ));

      // Create sample journals and entries
      final journalId1 = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 5))),
        description: const Value('Initial Cash Investment'),
        referenceNumber: const Value('JE001'),
      ));

      // Cash investment entry
      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId1),
        accountId: Value(cashAccountId),
        type: const Value('debit'),
        amount: const Value(10000.0),
        note: const Value('Initial investment'),
      ));

      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId1),
        accountId: Value(revenueAccountId),
        type: const Value('credit'),
        amount: const Value(10000.0),
        note: const Value('Investment revenue'),
      ));

      // Service revenue entry
      final journalId2 = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 3))),
        description: const Value('Service Revenue'),
        referenceNumber: const Value('JE002'),
      ));

      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId2),
        accountId: Value(cashAccountId),
        type: const Value('debit'),
        amount: const Value(2500.0),
        note: const Value('Service income'),
      ));

      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId2),
        accountId: Value(revenueAccountId),
        type: const Value('credit'),
        amount: const Value(2500.0),
        note: const Value('Service income'),
      ));

      // Office supplies expense
      final journalId3 = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 1))),
        description: const Value('Office Supplies Purchase'),
        referenceNumber: const Value('JE003'),
      ));

      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId3),
        accountId: Value(expenseAccountId),
        type: const Value('debit'),
        amount: const Value(150.0),
        note: const Value('Office supplies'),
      ));

      await database.createEntry(EntriesCompanion(
        journalId: Value(journalId3),
        accountId: Value(cashAccountId),
        type: const Value('credit'),
        amount: const Value(150.0),
        note: const Value('Office supplies payment'),
      ));

      print('Sample data generated successfully');
    } catch (e) {
      print('Error generating sample data: $e');
    }
  }
}
