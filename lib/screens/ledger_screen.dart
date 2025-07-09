import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../data/database.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  Account? _selectedAccount;
  DateTimeRange? _dateRange;
  int? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 48, 0, 0),
        child: Column(
          children: [
            _buildFilterChips(),
            _buildAccountSelector(),
            if (_selectedAccount != null) _buildLedgerView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: [
          if (_dateRange != null)
            FilterChip(
              label: Text(
                '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
              ),
              onSelected: (selected) {
                if (!selected) {
                  setState(() {
                    _dateRange = null;
                  });
                }
              },
              onDeleted: () {
                setState(() {
                  _dateRange = null;
                });
              },
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (_selectedGroupId != null)
            Consumer(
              builder: (context, ref, child) {
                final groupAsync = ref.watch(accountGroupProvider(_selectedGroupId!));
                return groupAsync.when(
                  loading: () => const SizedBox(),
                  error: (error, stackTrace) => const SizedBox(),
                  data: (group) => FilterChip(
                    label: Text('Group: ${group.name}'),
                    onSelected: (selected) {
                      if (!selected) {
                        setState(() {
                          _selectedGroupId = null;
                          _selectedAccount = null;
                        });
                      }
                    },
                    onDeleted: () {
                      setState(() {
                        _selectedGroupId = null;
                        _selectedAccount = null;
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                );
              },
            ),
          ActionChip(
            label: const Text('Add Filter'),
            onPressed: _showFilterDialog,
            avatar: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    final accountsAsync = _selectedGroupId != null
        ? ref.watch(accountsByGroupProvider(_selectedGroupId!))
        : ref.watch(accountsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
              data: (accounts) => DropdownButtonFormField<Account>(
                value: _selectedAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose an account',
                ),
                items: accounts.map((account) => DropdownMenuItem(
                  value: account,
                  child: Text(account.name),
                )).toList(),
                onChanged: (account) {
                  setState(() {
                    _selectedAccount = account;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerView() {
    if (_selectedAccount == null) return const SizedBox();
    
    final entriesAsync = ref.watch(entriesByAccountProvider(_selectedAccount!.id));
    final balanceAsync = ref.watch(accountBalanceProvider(_selectedAccount!.id));

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedAccount!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      balanceAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stackTrace) => Text('Error: $error'),
                        data: (balance) => Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Current Balance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(balance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Column headers
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Debit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Credit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Balance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
            
            // Entries
            Expanded(
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  // Filter entries by date range if selected
                  var filteredEntries = entries;
                  if (_dateRange != null) {
                    filteredEntries = entries.where((entry) {
                      return entry.createdAt.isAfter(_dateRange!.start) &&
                             entry.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
                    }).toList();
                  }
                  
                  // Sort by date
                  filteredEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  
                  // Calculate running balance
                  double runningBalance = 0.0;
                  
                  return ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      
                      // Update running balance
                      if (entry.type == 'debit') {
                        runningBalance += entry.amount;
                      } else {
                        runningBalance -= entry.amount;
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                DateFormat('MMM dd').format(entry.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Journal #${entry.journalId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (entry.note != null)
                                    Text(
                                      entry.note!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.type == 'debit'
                                    ? NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(entry.amount)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.type == 'credit'
                                    ? NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(entry.amount)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(runningBalance),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: runningBalance >= 0 ? Colors.green : Colors.red,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range filter
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: _dateRange != null
                  ? Text('${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}')
                  : const Text('All dates'),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() {
                    _dateRange = range;
                  });
                }
              },
            ),
            
            // Group filter
            Consumer(
              builder: (context, ref, child) {
                final groupsAsync = ref.watch(accountGroupsProvider);
                return groupsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => ListTile(
                    leading: const Icon(Icons.error),
                    title: Text('Error: $error'),
                  ),
                  data: (groups) => ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Account Group'),
                    subtitle: _selectedGroupId != null
                        ? Text(groups.firstWhere((g) => g.id == _selectedGroupId).name)
                        : const Text('All groups'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Group'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('All Groups'),
                                onTap: () {
                                  setState(() {
                                    _selectedGroupId = null;
                                    _selectedAccount = null;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                              ...groups.map((group) => ListTile(
                                title: Text(group.name),
                                onTap: () {
                                  setState(() {
                                    _selectedGroupId = group.id;
                                    _selectedAccount = null;
                                  });
                                  Navigator.of(context).pop();
                                },
                              )).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
                _selectedGroupId = null;
                _selectedAccount = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
