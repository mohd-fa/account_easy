import 'package:drift/drift.dart';
import 'database.dart';

class SampleDataGenerator {
  static Future<void> generateSampleData(AppDatabase database) async {
    try {
      // Check if sample data already exists
      final existingAccounts = await database.getAllAccounts();
      if (existingAccounts.isNotEmpty) return;
      
      // Get account groups
      final groups = await database.getAllAccountGroups();
      if (groups.isEmpty) return;
      
      final assetsGroup = groups.firstWhere((g) => g.name == 'Assets');
      final liabilitiesGroup = groups.firstWhere((g) => g.name == 'Liabilities');
      final revenueGroup = groups.firstWhere((g) => g.name == 'Revenue');
      final expensesGroup = groups.firstWhere((g) => g.name == 'Expenses');
      
      // Create sample accounts
      final cashAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Cash'),
        groupId: Value(assetsGroup.id),
      ));
      
      final bankAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Bank Account'),
        groupId: Value(assetsGroup.id),
      ));
      
      final salesAccountId = await database.createAccount(AccountsCompanion(
        name: const Value('Sales Revenue'),
        groupId: Value(revenueGroup.id),
      ));
      
      final rentExpenseId = await database.createAccount(AccountsCompanion(
        name: const Value('Rent Expense'),
        groupId: Value(expensesGroup.id),
      ));
      
      final loansPayableId = await database.createAccount(AccountsCompanion(
        name: const Value('Loans Payable'),
        groupId: Value(liabilitiesGroup.id),
      ));
      
      // Create sample journals
      final journal1Id = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 30))),
        description: const Value('Initial cash deposit'),
        referenceNumber: const Value('JE001'),
      ));
      
      final journal2Id = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 25))),
        description: const Value('Sales transaction'),
        referenceNumber: const Value('JE002'),
      ));
      
      final journal3Id = await database.createJournal(JournalsCompanion(
        date: Value(DateTime.now().subtract(const Duration(days: 15))),
        description: const Value('Rent payment'),
        referenceNumber: const Value('JE003'),
      ));
      
      // Create sample entries
      // Journal 1: Cash deposit
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal1Id),
        accountId: Value(cashAccountId),
        type: const Value('debit'),
        amount: const Value(10000.0),
        note: const Value('Opening balance'),
      ));
      
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal1Id),
        accountId: Value(loansPayableId),
        type: const Value('credit'),
        amount: const Value(10000.0),
        note: const Value('Loan received'),
      ));
      
      // Journal 2: Sales
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal2Id),
        accountId: Value(bankAccountId),
        type: const Value('debit'),
        amount: const Value(5000.0),
        note: const Value('Payment received'),
      ));
      
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal2Id),
        accountId: Value(salesAccountId),
        type: const Value('credit'),
        amount: const Value(5000.0),
        note: const Value('Sales made'),
      ));
      
      // Journal 3: Rent
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal3Id),
        accountId: Value(rentExpenseId),
        type: const Value('debit'),
        amount: const Value(1200.0),
        note: const Value('Monthly rent'),
      ));
      
      await database.createEntry(EntriesCompanion(
        journalId: Value(journal3Id),
        accountId: Value(cashAccountId),
        type: const Value('credit'),
        amount: const Value(1200.0),
        note: const Value('Rent paid'),
      ));
      
      print('Sample data generated successfully');
    } catch (e) {
      print('Error creating sample data: $e');
    }
  }
}
