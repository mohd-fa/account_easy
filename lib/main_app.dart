import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/account_book_screen.dart';
import 'screens/create_journal_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/settings_screen.dart';
import 'data/database.dart';
import 'providers/providers.dart';
import 'utils/sample_data.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AccountBookScreen(),
    const CreateJournalScreen(),
    const LedgerScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final database = ref.read(databaseProvider);
    await database.initializeDefaultGroups();
    await SampleDataGenerator.generateSampleData(database);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Easy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _currentIndex,
          height: 60.0,
          items: const <Widget>[
            Icon(Icons.dashboard, size: 30, color: Colors.white),
            Icon(Icons.account_balance_wallet, size: 30, color: Colors.white),
            Icon(Icons.add, size: 30, color: Colors.white),
            Icon(Icons.book, size: 30, color: Colors.white),
            Icon(Icons.settings, size: 30, color: Colors.white),
          ],
          color: Colors.deepPurple,
          buttonBackgroundColor: Colors.deepPurple.shade400,
          backgroundColor: Colors.grey.shade100,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}
