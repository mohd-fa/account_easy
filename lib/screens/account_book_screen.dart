import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../providers/providers.dart';
import '../data/database.dart';

class AccountBookScreen extends ConsumerWidget {
  const AccountBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountGroupsAsync = ref.watch(accountGroupsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Book'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'No account groups found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildAccountGroupCard(context, ref, group);
            },
          );
        },
      ),
    );
  }

  Widget _buildAccountGroupCard(BuildContext context, WidgetRef ref, AccountGroup group) {
    final accountsAsync = ref.watch(accountsByGroupProvider(group.id));
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: accountsAsync.when(
          loading: () => const Text('Loading...'),
          error: (error, stackTrace) => const Text('Error loading accounts'),
          data: (accounts) => Text('${accounts.length} accounts'),
        ),
        children: [
          accountsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Error: $error')),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'No accounts in this group',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddAccountDialog(context, ref, group.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Account'),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: accounts.map((account) => _buildAccountTile(context, ref, account)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, WidgetRef ref, Account account) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        child: const Icon(Icons.account_balance, color: Colors.deepPurple),
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: balanceAsync.when(
        loading: () => const Text('Loading balance...'),
        error: (error, stackTrace) => const Text('Error loading balance'),
        data: (balance) => Text(
          'Balance: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(balance)}',
          style: TextStyle(
            color: balance >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAccountDetails(context, ref, account),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref, [int? groupId]) {
    final nameController = TextEditingController();
    int? selectedGroupId = groupId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (groupId == null)
                Consumer(
                  builder: (context, ref, child) {
                    final groupsAsync = ref.watch(accountGroupsProvider);
                    return groupsAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) => Text('Error: $error'),
                      data: (groups) => DropdownButtonFormField<int>(
                        value: selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Account Group',
                          border: OutlineInputBorder(),
                        ),
                        items: groups.map((group) => DropdownMenuItem(
                          value: group.id,
                          child: Text(group.name),
                        )).toList(),
                        onChanged: (value) => selectedGroupId = value,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && selectedGroupId != null) {
                try {
                  final repository = ref.read(accountRepositoryProvider);
                  await repository.create(AccountsCompanion(
                    name: Value(nameController.text),
                    groupId: Value(selectedGroupId!),
                  ));
                  
                  ref.invalidate(accountsProvider);
                  ref.invalidate(accountsByGroupProvider(selectedGroupId!));
                  
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating account: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAccountDetails(BuildContext context, WidgetRef ref, Account account) {
    final entriesAsync = ref.watch(entriesByAccountProvider(account.id));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final balanceAsync = ref.watch(accountBalanceProvider(account.id));
                return balanceAsync.when(
                  loading: () => const Text('Loading balance...'),
                  error: (error, stackTrace) => Text('Error: $error'),
                  data: (balance) => Text(
                    'Current Balance: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(balance)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: entry.type == 'debit' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            entry.type == 'debit' ? Icons.add : Icons.remove,
                            color: entry.type == 'debit' ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          '${entry.type.toUpperCase()}: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.amount)}',
                          style: TextStyle(
                            color: entry.type == 'debit' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: entry.note != null ? Text(entry.note!) : null,
                        trailing: Text(
                          DateFormat('MMM dd, yyyy').format(entry.createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
