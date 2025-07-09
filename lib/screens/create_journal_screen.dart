import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../providers/providers.dart';
import '../data/database.dart';

class CreateJournalScreen extends ConsumerStatefulWidget {
  const CreateJournalScreen({super.key});

  @override
  ConsumerState<CreateJournalScreen> createState() => _CreateJournalScreenState();
}

class _CreateJournalScreenState extends ConsumerState<CreateJournalScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Page 1 controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  // Page 2 controllers
  final List<JournalEntry> _debitEntries = [];
  final List<JournalEntry> _creditEntries = [];
  bool _isDebitFocused = true;
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF556B2F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Journal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentPage == 1)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _saveJournal,
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPage1(),
                _buildPage2(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Previous'),
              )
            else
              const SizedBox(),
            if (_currentPage < 1)
              ElevatedButton(
                onPressed: () {
                  if (_validatePage1()) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: const Text('Next'),
              )
            else
              ElevatedButton(
                onPressed: _saveJournal,
                child: const Text('Save'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Date picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Reference number field
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference Number (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
            ),
          ),
          
          const SizedBox(height: 80), // Add space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Toggle buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isDebitFocused = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDebitFocused ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Debit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isDebitFocused = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isDebitFocused ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Credit'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Balance display
          _buildBalanceDisplay(),
          
          const SizedBox(height: 16),
          
          // Entry section
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: AnimatedCrossFade(
              firstChild: _buildEntrySection(_debitEntries, 'Debit', Colors.green),
              secondChild: _buildEntrySection(_creditEntries, 'Credit', Colors.red),
              crossFadeState: _isDebitFocused 
                  ? CrossFadeState.showFirst 
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
          ),
          
          const SizedBox(height: 80), // Add space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    final debitTotal = _debitEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final creditTotal = _creditEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final difference = debitTotal - creditTotal;
    
    return Card(
      color: difference == 0 ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Debit Total: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(debitTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Credit Total: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(creditTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Difference: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(difference.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: difference == 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrySection(List<JournalEntry> entries, String type, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$type Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            IconButton(
              onPressed: () => _showAddEntryDialog(entries, type.toLowerCase()),
              icon: Icon(Icons.add, color: color),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        if (entries.isEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No $type entries yet',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      entry.accountName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: entry.note != null ? Text(
                      entry.note!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              entries.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAddEntryDialog(List<JournalEntry> entries, String type) {
    final accountController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    int? selectedAccountId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final accountsAsync = ref.watch(accountsProvider);
                  return accountsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stackTrace) => Text('Error: $error'),
                    data: (accounts) => DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      )).toList(),
                      onChanged: (value) {
                        selectedAccountId = value;
                        final account = accounts.firstWhere((a) => a.id == value);
                        accountController.text = account.name;
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            onPressed: () {
              if (selectedAccountId != null && amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    entries.add(JournalEntry(
                      accountId: selectedAccountId!,
                      accountName: accountController.text,
                      amount: amount,
                      note: noteController.text.isNotEmpty ? noteController.text : null,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  bool _validatePage1() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return false;
    }
    return true;
  }

  bool _validatePage2() {
    if (_debitEntries.isEmpty && _creditEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one entry')),
      );
      return false;
    }
    
    final debitTotal = _debitEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final creditTotal = _creditEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    if (debitTotal != creditTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debit and credit totals must be equal')),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _saveJournal() async {
    if (!_validatePage2()) return;
    
    try {
      final journalRepository = ref.read(journalRepositoryProvider);
      final entryRepository = ref.read(entryRepositoryProvider);
      
      // Create journal
      final journalId = await journalRepository.create(JournalsCompanion(
        date: Value(_selectedDate),
        description: Value(_descriptionController.text),
        referenceNumber: _referenceController.text.isNotEmpty 
            ? Value(_referenceController.text)
            : const Value.absent(),
      ));
      
      // Create entries
      for (final entry in _debitEntries) {
        await entryRepository.create(EntriesCompanion(
          journalId: Value(journalId),
          accountId: Value(entry.accountId),
          type: const Value('debit'),
          amount: Value(entry.amount),
          note: entry.note != null ? Value(entry.note!) : const Value.absent(),
        ));
      }
      
      for (final entry in _creditEntries) {
        await entryRepository.create(EntriesCompanion(
          journalId: Value(journalId),
          accountId: Value(entry.accountId),
          type: const Value('credit'),
          amount: Value(entry.amount),
          note: entry.note != null ? Value(entry.note!) : const Value.absent(),
        ));
      }
      
      // Invalidate providers to refresh data
      ref.invalidate(journalsProvider);
      ref.invalidate(entriesProvider);
      ref.invalidate(groupTotalsProvider);
      
      // Clear form
      _descriptionController.clear();
      _referenceController.clear();
      _selectedDate = DateTime.now();
      _debitEntries.clear();
      _creditEntries.clear();
      
      // Reset to first page
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating journal: $e')),
      );
    }
  }
}

class JournalEntry {
  final int accountId;
  final String accountName;
  final double amount;
  final String? note;

  JournalEntry({
    required this.accountId,
    required this.accountName,
    required this.amount,
    this.note,
  });
}
