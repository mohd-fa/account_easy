import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        children: [
          _buildSection(
            'Application',
            [
              _buildSettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: _appVersion,
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            'Data Management',
            [
              _buildSettingsTile(
                icon: Icons.upload_file,
                title: 'Export Database',
                subtitle: 'Export all data to a file',
                onTap: () => _exportDatabase(),
              ),
              _buildSettingsTile(
                icon: Icons.download,
                title: 'Import Database',
                subtitle: 'Import data from a file',
                onTap: () => _importDatabase(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            'Danger Zone',
            [
              _buildSettingsTile(
                icon: Icons.warning,
                title: 'Reset All Data',
                subtitle: 'Delete all journals and entries',
                onTap: () => _showResetDialog(),
                isDestructive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            'About',
            [
              _buildSettingsTile(
                icon: Icons.book,
                title: 'User Guide',
                subtitle: 'Learn how to use the app',
                onTap: () => _showUserGuide(),
              ),
              _buildSettingsTile(
                icon: Icons.contact_support,
                title: 'Support',
                subtitle: 'Get help or report issues',
                onTap: () => _showSupport(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.deepPurple,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red.shade300 : Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Account Easy',
      applicationVersion: _appVersion,
      applicationIcon: const Icon(
        Icons.account_balance,
        size: 48,
        color: Colors.deepPurple,
      ),
      children: [
        const Text(
          'A double-entry journal-based accounting software built with Flutter and Drift ORM.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Double-entry bookkeeping'),
        const Text('• Account grouping'),
        const Text('• Journal entries'),
        const Text('• Ledger reports'),
        const Text('• Data export/import'),
      ],
    );
  }

  void _exportDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Database'),
        content: const Text(
          'This feature will export all your data to a file. The exported file can be used to restore your data later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement database export
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon!'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _importDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Database'),
        content: const Text(
          'This feature will import data from a previously exported file. This will replace all current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement database import
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import feature coming soon!'),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'Are you sure you want to delete all data? This action cannot be undone.\n\nThis will remove:\n• All journal entries\n• All custom accounts\n• All transaction history\n\nDefault account groups will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmReset(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" to confirm that you want to permanently delete all data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final database = ref.read(databaseProvider);
                
                // Delete all entries
                await database.delete(database.entries).go();
                
                // Delete all journals
                await database.delete(database.journals).go();
                
                // Delete all custom accounts (keep default groups)
                await database.delete(database.accounts).go();
                
                // Invalidate all providers
                ref.invalidate(journalsProvider);
                ref.invalidate(entriesProvider);
                ref.invalidate(accountsProvider);
                ref.invalidate(groupTotalsProvider);
                
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close reset dialog
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been reset'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error resetting data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Getting Started',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Create accounts in different groups (Assets, Liabilities, etc.)'),
              Text('2. Create journal entries following double-entry rules'),
              Text('3. View your account balances in the dashboard'),
              Text('4. Check detailed ledger reports for any account'),
              
              SizedBox(height: 16),
              Text(
                'Double-Entry Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Every transaction must have equal debit and credit amounts'),
              Text('• Debits increase assets and expenses'),
              Text('• Credits increase liabilities, equity, and revenue'),
              
              SizedBox(height: 16),
              Text(
                'Navigation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Dashboard: Overview of all accounts'),
              Text('• Account Book: Manage accounts and groups'),
              Text('• Create Journal: Add new transactions'),
              Text('• Ledger: Detailed account reports'),
              Text('• Settings: App configuration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text(
          'For support, questions, or to report issues:\n\n'
          '• Check the User Guide first\n'
          '• Review the app documentation\n'
          '• Contact the development team\n\n'
          'This is a demo application for educational purposes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
