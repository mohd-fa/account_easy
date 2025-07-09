import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../data/database.dart';
import 'journal_detail_screen.dart';

class JournalViewScreen extends ConsumerStatefulWidget {
  const JournalViewScreen({super.key});

  @override
  ConsumerState<JournalViewScreen> createState() => _JournalViewScreenState();
}

class _JournalViewScreenState extends ConsumerState<JournalViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Journal Entries',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          _buildSearchAndFilters(),
          Expanded(
            child: _buildJournalsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search journals...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Active filters
          if (_dateRange != null)
            Wrap(
              spacing: 8,
              children: [
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
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildJournalsList() {
    final journalsAsync = ref.watch(journalsProvider);
    
    return journalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
      data: (journals) {
        // Filter journals based on search query and date range
        var filteredJournals = journals.where((journal) {
          final matchesSearch = _searchQuery.isEmpty ||
              journal.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (journal.referenceNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final matchesDate = _dateRange == null ||
              (journal.date.isAfter(_dateRange!.start) &&
               journal.date.isBefore(_dateRange!.end.add(const Duration(days: 1))));
          
          return matchesSearch && matchesDate;
        }).toList();

        if (filteredJournals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty && _dateRange == null
                      ? 'No journals found'
                      : 'No journals match your filters',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first journal entry to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredJournals.length,
          itemBuilder: (context, index) {
            final journal = filteredJournals[index];
            return _buildJournalCard(journal);
          },
        );
      },
    );
  }

  Widget _buildJournalCard(Journal journal) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showJournalDetails(journal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(journal.date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
                  if (journal.referenceNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        journal.referenceNumber!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                journal.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(journal.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Journals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: _dateRange != null
                  ? Text('${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}')
                  : const Text('Any date'),
              onTap: () async {
                final dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _dateRange,
                );
                if (dateRange != null) {
                  setState(() {
                    _dateRange = dateRange;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showJournalDetails(Journal journal) {
    final entriesAsync = ref.watch(entriesByJournalProvider(journal.id));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal Details',
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
            
            // Journal Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(journal.date)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (journal.referenceNumber != null)
                          Text(
                            'Ref: ${journal.referenceNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description: ${journal.description}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Entries List
            Expanded(
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(child: Text('No entries found'));
                  }
                  
                  double debitTotal = 0;
                  double creditTotal = 0;
                  
                  for (final entry in entries) {
                    if (entry.type == 'debit') {
                      debitTotal += entry.amount;
                    } else {
                      creditTotal += entry.amount;
                    }
                  }
                  
                  return Column(
                    children: [
                      // Totals
                      Card(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Debit: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(debitTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Total Credit: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(creditTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Entries
                      Expanded(
                        child: ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Consumer(
                              builder: (context, ref, child) {
                                final accountAsync = ref.watch(accountProvider(entry.accountId));
                                return accountAsync.when(
                                  loading: () => const ListTile(title: Text('Loading...')),
                                  error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
                                  data: (account) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
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
                                        account.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: entry.note != null ? Text(entry.note!) : null,
                                      trailing: Text(
                                        '${entry.type.toUpperCase()}: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(entry.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: entry.type == 'debit' ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
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
