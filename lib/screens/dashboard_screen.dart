import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../data/database.dart';
import '../widgets/responsive_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupTotalsAsync = ref.watch(groupTotalsProvider);
    final journalsAsync = ref.watch(journalsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ScrollableColumn(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary Cards
          _buildSummaryCards(context, groupTotalsAsync, journalsAsync, accountsAsync),
          const SizedBox(height: 24),
          
          // Charts Section
          _buildChartsSection(context, groupTotalsAsync),
          const SizedBox(height: 24),
          
          // Recent Journals
          _buildRecentJournals(context, journalsAsync),
          const SizedBox(height: 80), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncValue<Map<String, double>> groupTotals,
    AsyncValue<List<Journal>> journals,
    AsyncValue<List<Account>> accounts,
  ) {
    return groupTotals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (totals) {
        final journalCount = journals.valueOrNull?.length ?? 0;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            final childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.2;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              children: [
                ResponsiveSummaryCard(
                  title: 'Assets',
                  value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totals['Assets'] ?? 0.0),
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  isAmount: true,
                ),
                ResponsiveSummaryCard(
                  title: 'Liabilities',
                  value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totals['Liabilities'] ?? 0.0),
                  icon: Icons.credit_card,
                  color: Colors.red,
                  isAmount: true,
                ),
                ResponsiveSummaryCard(
                  title: 'Equity',
                  value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totals['Equity'] ?? 0.0),
                  icon: Icons.pie_chart,
                  color: Colors.blue,
                  isAmount: true,
                ),
                ResponsiveSummaryCard(
                  title: 'Revenue',
                  value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totals['Revenue'] ?? 0.0),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  isAmount: true,
                ),
                ResponsiveSummaryCard(
                  title: 'Expenses',
                  value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totals['Expenses'] ?? 0.0),
                  icon: Icons.trending_down,
                  color: Colors.purple,
                  isAmount: true,
                ),
                ResponsiveSummaryCard(
                  title: 'Journals',
                  value: journalCount.toString(),
                  icon: Icons.book,
                  color: Colors.teal,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    AsyncValue<Map<String, double>> groupTotals,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Groups Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: groupTotals.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
                data: (totals) {
                  final hasData = totals.values.any((value) => value.abs() > 0);
                  
                  if (!hasData) {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  return PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(totals),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> totals) {
    final colors = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];
    
    final entries = totals.entries.where((entry) => entry.value.abs() > 0).toList();
    final total = entries.fold(0.0, (sum, entry) => sum + entry.value.abs());
    
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value.abs() / total) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value.abs(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildRecentJournals(
    BuildContext context,
    AsyncValue<List<Journal>> journalsAsync,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Journals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            journalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Error: $error')),
              data: (journals) {
                if (journals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No journals yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                final recentJournals = journals.take(5).toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentJournals.length,
                  itemBuilder: (context, index) {
                    final journal = recentJournals[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        child: const Icon(Icons.receipt, color: Colors.deepPurple),
                      ),
                      title: Text(
                        journal.description,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(journal.date),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: journal.referenceNumber != null
                          ? Chip(
                              label: Text(
                                journal.referenceNumber!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade200,
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
