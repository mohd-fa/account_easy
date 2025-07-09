import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

// Refresh notifier to trigger provider updates
final refreshProvider = StateProvider<int>((ref) => 0);

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Account Groups providers
final accountGroupsProvider = FutureProvider<List<AccountGroup>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAllAccountGroups();
});

final accountGroupProvider = FutureProvider.family<AccountGroup, int>((ref, id) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAccountGroupById(id);
});

// Accounts providers
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAllAccounts();
});

final accountsByGroupProvider = FutureProvider.family<List<Account>, int>((ref, groupId) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAccountsByGroup(groupId);
});

final accountProvider = FutureProvider.family<Account, int>((ref, id) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAccountById(id);
});

// Journals providers
final journalsProvider = FutureProvider<List<Journal>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAllJournals();
});

final journalProvider = FutureProvider.family<Journal, int>((ref, id) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getJournalById(id);
});

// Entries providers
final entriesProvider = FutureProvider<List<Entry>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAllEntries();
});

final entriesByJournalProvider = FutureProvider.family<List<Entry>, int>((ref, journalId) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getEntriesByJournal(journalId);
});

final entriesByAccountProvider = FutureProvider.family<List<Entry>, int>((ref, accountId) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getEntriesByAccount(accountId);
});

final entriesWithDetailsProvider = FutureProvider<List<EntryWithDetails>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getEntriesWithDetails();
});

// Balance providers
final accountBalanceProvider = FutureProvider.family<double, int>((ref, accountId) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getAccountBalance(accountId);
});

// Bulk balance provider for better performance
final accountBalancesProvider = FutureProvider.family<Map<int, double>, int>((ref, groupId) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  final accounts = await database.getAccountsByGroup(groupId);
  final accountIds = accounts.map((a) => a.id).toList();
  return database.getAccountBalances(accountIds);
});

final groupTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(refreshProvider); // Watch refresh state
  final database = ref.watch(databaseProvider);
  return database.getGroupTotals();
});

// Repository providers for mutations
final accountGroupRepositoryProvider = Provider<AccountGroupRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountGroupRepository(database);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountRepository(database);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return JournalRepository(database);
});

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return EntryRepository(database);
});

// Repository classes
class AccountGroupRepository {
  final AppDatabase _database;

  AccountGroupRepository(this._database);

  Future<int> create(AccountGroupsCompanion entry) async {
    return await _database.createAccountGroup(entry);
  }

  Future<bool> update(AccountGroup group) async {
    return await _database.updateAccountGroup(group);
  }

  Future<int> delete(int id) async {
    return await _database.deleteAccountGroup(id);
  }
}

class AccountRepository {
  final AppDatabase _database;

  AccountRepository(this._database);

  Future<int> create(AccountsCompanion entry) async {
    return await _database.createAccount(entry);
  }

  Future<bool> update(Account account) async {
    return await _database.updateAccount(account);
  }

  Future<int> delete(int id) async {
    return await _database.deleteAccount(id);
  }
}

class JournalRepository {
  final AppDatabase _database;

  JournalRepository(this._database);

  Future<int> create(JournalsCompanion entry) async {
    return await _database.createJournal(entry);
  }

  Future<bool> update(Journal journal) async {
    return await _database.updateJournal(journal);
  }

  Future<int> delete(int id) async {
    return await _database.deleteJournal(id);
  }
}

class EntryRepository {
  final AppDatabase _database;

  EntryRepository(this._database);

  Future<int> create(EntriesCompanion entry) async {
    return await _database.createEntry(entry);
  }

  Future<bool> update(Entry entry) async {
    return await _database.updateEntry(entry);
  }

  Future<int> delete(int id) async {
    return await _database.deleteEntry(id);
  }
}
