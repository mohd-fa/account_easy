import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../providers/providers.dart';
import '../data/database.dart';
import 'account_detail_screen.dart';

class AccountBookScreen extends ConsumerWidget {
  const AccountBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountGroupsAsync = ref.watch(accountGroupsProvider);
    
    return Scaffold(
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
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
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
    final balancesAsync = ref.watch(accountBalancesProvider(group.id));
    
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
              
              return balancesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('Error loading balances: $error')),
                ),
                data: (balances) => Column(
                  children: [
                    ...accounts.map((account) => _buildAccountTile(context, ref, account, balances[account.id] ?? 0.0)).toList(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddAccountDialog(context, ref, group.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF556B2F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, WidgetRef ref, Account account, double balance) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF556B2F).withOpacity(0.1),
        child: const Icon(Icons.account_balance, color: Color(0xFF556B2F)),
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Balance: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(balance)}',
        style: TextStyle(
          color: balance >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
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
                  
                  // Trigger refresh for all providers
                  ref.read(refreshProvider.notifier).state++;
                  
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountDetailScreen(accountId: account.id),
      ),
    );
  }
}
