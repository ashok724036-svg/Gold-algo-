import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/trading_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hindi = ref.watch(isHindiProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.account_balance_wallet_outlined, color: AppTheme.gold),
                title: Text('Paper account'),
                subtitle: Text('\$10,000 initial balance · USD'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.security_outlined, color: AppTheme.green),
                title: Text('Risk controls'),
                subtitle: Text('1.0% risk · 3 max open trades · 1.0 max lot'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: hindi,
                onChanged: (_) => ref.read(isHindiProvider.notifier).state = !hindi,
                title: const Text('Hindi labels'),
                subtitle: Text(hindi ? 'हिंदी' : 'English'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.notifications_none_rounded),
                title: Text('Notifications'),
                subtitle: Text('Bot signals and daily risk alerts'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.storage_outlined),
                title: Text('Offline cache'),
                subtitle: Text('Last sync: just now · 30 days of candles'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_done_outlined, color: AppTheme.green),
            title: Text('Live market data'),
            subtitle: Text('XAU/USD candles sync automatically from Supabase'),
          ),
        ),
        const SizedBox(height: 22),
        const Center(child: Text('GoldScalper Pro 1.0.0 · PAPER ONLY', style: TextStyle(color: AppTheme.muted, fontSize: 11, letterSpacing: 1))),
      ],
    );
  }
}