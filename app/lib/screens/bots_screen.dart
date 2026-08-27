import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/trading_provider.dart';

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  Future<void> upload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['py', 'json'],
      withData: true,
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.files.single.name} imported as a draft bot')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = ref.watch(botsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(child: Text('My bots', style: Theme.of(context).textTheme.headlineSmall)),
            IconButton.filled(onPressed: () => upload(context), icon: const Icon(Icons.upload_file_rounded)),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Run custom Python or JSON strategies in paper mode.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 20),
        Card(
          color: AppTheme.gold.withOpacity(.10),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.gold),
                SizedBox(width: 12),
                Expanded(child: Text('Every live decision is sandboxed and stays in the paper account.')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...bots.map((bot) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                value: bot.active,
                onChanged: (_) => ref.read(botsProvider.notifier).toggle(bot.id),
                secondary: CircleAvatar(
                  backgroundColor: bot.active ? AppTheme.green.withOpacity(.14) : AppTheme.surface,
                  child: Icon(bot.active ? Icons.bolt_rounded : Icons.smart_toy_outlined, color: bot.active ? AppTheme.green : AppTheme.muted),
                ),
                title: Text(bot.name),
                subtitle: Text('${bot.strategy}\n${bot.trades} total trades'),
                isThreeLine: true,
                activeColor: AppTheme.green,
              ),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => upload(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Import strategy file'),
        ),
      ],
    );
  }
}