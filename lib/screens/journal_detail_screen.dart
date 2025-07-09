import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../data/database.dart';

class JournalDetailScreen extends ConsumerWidget {
  final int journalId;
  
  const JournalDetailScreen({
    super.key,
    required this.journalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalProvider(journalId));
    final entriesAsync = ref.watch(entriesByJournalProvider(journalId));
    final accountsAsync = ref.watch(accountsProvider);

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
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Journal Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: journalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Error: $error')),
              data: (journal) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Journal Information Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Journal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (journal.referenceNumber != null)
                                  Chip(
                                    label: Text(
                                      journal.referenceNumber!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF556B2F),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Date', DateFormat('MMM dd, yyyy').format(journal.date)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Description', journal.description),
                            const SizedBox(height: 8),
                            _buildInfoRow('Created', DateFormat('MMM dd, yyyy - HH:mm').format(journal.createdAt)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Journal Entries
                    entriesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(child: Text('Error: $error')),
                      data: (entries) => accountsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(child: Text('Error: $error')),
                        data: (accounts) {
                          final accountMap = {for (var account in accounts) account.id: account};
                          final debitEntries = entries.where((e) => e.type == 'debit').toList();
                          final creditEntries = entries.where((e) => e.type == 'credit').toList();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Journal Entries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Debit Entries
                              if (debitEntries.isNotEmpty) ...[
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.add_circle, color: Colors.green.shade600, size: 20),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Debit Entries',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...debitEntries.map((entry) => _buildEntryTile(
                                          entry,
                                          accountMap[entry.accountId]?.name ?? 'Unknown Account',
                                          Colors.green,
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              // Credit Entries
                              if (creditEntries.isNotEmpty) ...[
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.remove_circle, color: Colors.red.shade600, size: 20),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Credit Entries',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...creditEntries.map((entry) => _buildEntryTile(
                                          entry,
                                          accountMap[entry.accountId]?.name ?? 'Unknown Account',
                                          Colors.red,
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Total Balance Check
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                color: const Color(0xFF556B2F).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Balance Check',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _calculateBalance(debitEntries, creditEntries) == 0
                                            ? 'Balanced ✓'
                                            : 'Unbalanced ✗',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _calculateBalance(debitEntries, creditEntries) == 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryTile(Entry entry, String accountName, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (entry.note != null)
                  Text(
                    entry.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(entry.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBalance(List<Entry> debitEntries, List<Entry> creditEntries) {
    final debitTotal = debitEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final creditTotal = creditEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    return debitTotal - creditTotal;
  }
}
