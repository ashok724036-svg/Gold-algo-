import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'providers/trading_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/backtest_screen.dart';
import 'screens/bots_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

class GoldScalperApp extends ConsumerWidget {
  const GoldScalperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GoldScalper Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AppConfig.supabase?.auth.currentSession == null
          ? const AuthScreen()
          : const ShellScreen(),
    );
  }
}

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  static const pages = [
    DashboardScreen(),
    ChartScreen(),
    BotsScreen(),
    BacktestScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedNavProvider);
    return Scaffold(
      body: SafeArea(child: pages[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) =>
            ref.read(selectedNavProvider.notifier).state = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_rounded),
            label: 'Markets',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'Bots',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Backtest',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}