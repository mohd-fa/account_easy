import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Account Groups Table
class AccountGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Accounts Table
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get groupId => integer().references(AccountGroups, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Journals Table
class Journals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().withLength(min: 1, max: 200)();
  TextColumn get referenceNumber => text().withLength(max: 50).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Entries Table
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalId => integer().references(Journals, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get type => text().check(type.isIn(['debit', 'credit']))();
  RealColumn get amount => real().check(amount.isBiggerThanValue(0))();
  TextColumn get note => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [AccountGroups, Accounts, Journals, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'account_easy.db'));
      return NativeDatabase(file);
    });
  }

  // Account Groups Operations
  Future<List<AccountGroup>> getAllAccountGroups() => select(accountGroups).get();
  
  Future<AccountGroup> getAccountGroupById(int id) =>
      (select(accountGroups)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createAccountGroup(AccountGroupsCompanion entry) =>
      into(accountGroups).insert(entry);

  Future<bool> updateAccountGroup(AccountGroup group) =>
      update(accountGroups).replace(group);

  Future<int> deleteAccountGroup(int id) =>
      (delete(accountGroups)..where((tbl) => tbl.id.equals(id))).go();

  // Accounts Operations
  Future<List<Account>> getAllAccounts() => select(accounts).get();
  
  Future<List<Account>> getAccountsByGroup(int groupId) =>
      (select(accounts)..where((tbl) => tbl.groupId.equals(groupId))).get();

  Future<Account> getAccountById(int id) =>
      (select(accounts)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createAccount(AccountsCompanion entry) =>
      into(accounts).insert(entry);

  Future<bool> updateAccount(Account account) =>
      update(accounts).replace(account);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((tbl) => tbl.id.equals(id))).go();

  // Journals Operations
  Future<List<Journal>> getAllJournals() => 
      (select(journals)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Future<Journal> getJournalById(int id) =>
      (select(journals)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createJournal(JournalsCompanion entry) =>
      into(journals).insert(entry);

  Future<bool> updateJournal(Journal journal) =>
      update(journals).replace(journal);

  Future<int> deleteJournal(int id) =>
      (delete(journals)..where((tbl) => tbl.id.equals(id))).go();

  // Entries Operations
  Future<List<Entry>> getAllEntries() => select(entries).get();
  
  Future<List<Entry>> getEntriesByJournal(int journalId) =>
      (select(entries)..where((tbl) => tbl.journalId.equals(journalId))).get();

  Future<List<Entry>> getEntriesByAccount(int accountId) =>
      (select(entries)..where((tbl) => tbl.accountId.equals(accountId))).get();

  Future<int> createEntry(EntriesCompanion entry) =>
      into(entries).insert(entry);

  Future<bool> updateEntry(Entry entry) =>
      update(entries).replace(entry);

  Future<int> deleteEntry(int id) =>
      (delete(entries)..where((tbl) => tbl.id.equals(id))).go();

  // Complex Queries
  Future<List<EntryWithDetails>> getEntriesWithDetails() {
    final query = select(entries)
        .join([
          leftOuterJoin(accounts, accounts.id.equalsExp(entries.accountId)),
          leftOuterJoin(journals, journals.id.equalsExp(entries.journalId)),
          leftOuterJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId)),
        ]);
    
    return query.map((row) => EntryWithDetails(
      entry: row.readTable(entries),
      account: row.readTable(accounts),
      journal: row.readTable(journals),
      accountGroup: row.readTable(accountGroups),
    )).get();
  }

  Future<double> getAccountBalance(int accountId) async {
    final debits = await (selectOnly(entries)
        ..addColumns([entries.amount.sum()])
        ..where(entries.accountId.equals(accountId) & entries.type.equals('debit')))
        .getSingle();
    
    final credits = await (selectOnly(entries)
        ..addColumns([entries.amount.sum()])
        ..where(entries.accountId.equals(accountId) & entries.type.equals('credit')))
        .getSingle();
    
    final debitTotal = debits.read(entries.amount.sum()) ?? 0.0;
    final creditTotal = credits.read(entries.amount.sum()) ?? 0.0;
    
    return debitTotal - creditTotal;
  }

  Future<Map<String, double>> getGroupTotals() async {
    final result = <String, double>{};
    final groups = await getAllAccountGroups();
    
    for (final group in groups) {
      final groupAccounts = await getAccountsByGroup(group.id);
      double total = 0.0;
      
      for (final account in groupAccounts) {
        total += await getAccountBalance(account.id);
      }
      
      result[group.name] = total;
    }
    
    return result;
  }

  // Initialize default account groups
  Future<void> initializeDefaultGroups() async {
    final existingGroups = await getAllAccountGroups();
    if (existingGroups.isEmpty) {
      final defaultGroups = [
        'Assets',
        'Liabilities', 
        'Equity',
        'Revenue',
        'Expenses',
      ];
      
      for (final groupName in defaultGroups) {
        await createAccountGroup(AccountGroupsCompanion(
          name: Value(groupName),
          isDefault: const Value(true),
        ));
      }
    }
  }
}

// Custom data class for complex queries
class EntryWithDetails {
  final Entry entry;
  final Account? account;
  final Journal? journal;
  final AccountGroup? accountGroup;

  EntryWithDetails({
    required this.entry,
    this.account,
    this.journal,
    this.accountGroup,
  });
}
