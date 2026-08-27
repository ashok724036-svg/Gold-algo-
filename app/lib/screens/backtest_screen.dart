import 'package:flutter/material.dart';

import '../core/theme.dart';

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});
  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  bool running = false;
  String bot = 'EMA Cross Scalper V3';

  Future<void> run() async {
    setState(() => running = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Backtest lab', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Replay a strategy against historical XAUUSD candles.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: bot,
                  decoration: const InputDecoration(labelText: 'Strategy'),
                  items: const [
                    DropdownMenuItem(value: 'EMA Cross Scalper V3', child: Text('EMA Cross Scalper V3')),
                    DropdownMenuItem(value: 'RSI + Bollinger Scalper V3', child: Text('RSI + Bollinger Scalper V3')),
                  ],
                  onChanged: (value) => setState(() => bot = value ?? bot),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: _DateField(label: 'From', value: '01 Aug 2026')),
                    SizedBox(width: 10),
                    Expanded(child: _DateField(label: 'To', value: '27 Aug 2026')),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: running ? null : run,
                    icon: Icon(running ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
                    label: Text(running ? 'Running backtest…' : 'Run backtest'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Latest result', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('EMA Cross Scalper V3'),
                    Text('01–27 Aug 2026', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Result(label: 'Net P&L', value: '+\$842.30', color: AppTheme.green),
                    _Result(label: 'Win rate', value: '64.8%', color: AppTheme.gold),
                    _Result(label: 'Max DD', value: '-3.2%', color: AppTheme.red),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV export is ready when a backtest completes.'))),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export CSV report'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      );
}

class _Result extends StatelessWidget {
  const _Result({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      ]);
}