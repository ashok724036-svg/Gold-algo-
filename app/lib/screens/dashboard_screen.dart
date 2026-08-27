import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/trading_provider.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final positions = ref.watch(positionsProvider);
    final bots = ref.watch(botsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thursday, 27 Aug', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted)),
                  const SizedBox(height: 3),
                  Text('Good morning, trader', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.circle, size: 8, color: AppTheme.green),
                SizedBox(width: 6),
                Text('PAPER LIVE', style: TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paper equity', style: TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 5),
                Text('\$${account.equity.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('+1.85% this session', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                SizedBox(
                  height: 88,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: 10000,
                      maxY: 10300,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppTheme.gold,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          spots: const [
                            FlSpot(0, 10000), FlSpot(1, 10042), FlSpot(2, 10028),
                            FlSpot(3, 10114), FlSpot(4, 10102), FlSpot(5, 10176),
                            FlSpot(6, 10184),
                          ],
                          belowBarData: BarAreaData(show: true, color: AppTheme.gold.withValues(alpha: .10)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            MetricCard(label: 'Balance', value: '\$${account.balance.toStringAsFixed(0)}'),
            MetricCard(label: 'Daily P&L', value: '+\$${account.dailyPnl.toStringAsFixed(2)}', positive: true),
            const MetricCard(label: 'Win rate', value: '68.4%', detail: '128 closed trades'),
            const MetricCard(label: 'Profit factor', value: '1.82', detail: 'Last 30 days'),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Open positions', style: Theme.of(context).textTheme.titleMedium),
            Text('${positions.length} active', style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
        const SizedBox(height: 10),
        ...positions.map((position) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.green.withValues(alpha: .14),
                  child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.green),
                ),
                title: Text(position.bot),
                subtitle: Text('${position.side}  ·  ${position.lot.toStringAsFixed(2)} lots  ·  entry ${position.entry.toStringAsFixed(2)}'),
                trailing: Text('+\$${position.pnl.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
              ),
            )),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bot activity', style: Theme.of(context).textTheme.titleMedium),
            Text('${bots.where((bot) => bot.active).length} running', style: const TextStyle(color: AppTheme.green)),
          ],
        ),
        const SizedBox(height: 10),
        ...bots.take(2).map((bot) => Card(
              child: ListTile(
                leading: Icon(bot.active ? Icons.bolt_rounded : Icons.pause_circle_outline, color: bot.active ? AppTheme.gold : AppTheme.muted),
                title: Text(bot.name),
                subtitle: Text('${bot.trades} trades  ·  ${bot.strategy}'),
                trailing: Text(bot.active ? 'ACTIVE' : 'PAUSED', style: TextStyle(color: bot.active ? AppTheme.green : AppTheme.muted, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            )),
      ],
    );
  }
}