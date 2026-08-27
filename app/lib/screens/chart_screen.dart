import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/trading_models.dart';
import '../providers/trading_provider.dart';

class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(selectedTimeframeProvider);
    ref.listen<String>(selectedTimeframeProvider, (_, next) {
      ref.read(candlesProvider.notifier).load(next);
    });
    final market = ref.watch(candlesProvider);
    final candles = market.candles;
    final last = candles.isEmpty ? null : candles.last.close;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XAU/USD', style: Theme.of(context).textTheme.headlineSmall),
                  const Text('Gold spot · simulated spread 0.35', style: TextStyle(color: AppTheme.muted)),
                ],
              ),
            ),
            Text(last == null ? '—' : last.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['M1', 'M5', 'M15', 'M30', 'H1'].map((label) {
              final active = label == timeframe;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: active,
                  onSelected: (_) => ref.read(selectedTimeframeProvider.notifier).state = label,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: SizedBox(
            height: 390,
             child: Stack(
               children: [
                 if (candles.isNotEmpty)
                   CustomPaint(
                     size: Size.infinite,
                     painter: _CandlePainter(candles),
                   )
                 else
                   Center(
                     child: market.loading
                         ? const CircularProgressIndicator(color: AppTheme.gold)
                         : const Text('No candle data available', style: TextStyle(color: AppTheme.muted)),
                ),
                 Padding(
                   padding: const EdgeInsets.all(18),
                   child: Align(
                     alignment: Alignment.topLeft,
                     child: Text(
                       market.live ? 'LIVE  ·  ${timeframe.toLowerCase()}' : 'OFFLINE  ·  ${timeframe.toLowerCase()}',
                       style: TextStyle(
                         color: market.live ? AppTheme.green : AppTheme.gold,
                         fontSize: 11,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                 ),
               ],
            ),
          ),
        ),
         if (market.error != null) ...[
           const SizedBox(height: 10),
           Text(market.error!, style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
         ],
         const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  _Indicator(label: 'EMA 9', color: AppTheme.gold, value: '—'),
                  _Indicator(label: 'EMA 21', color: Colors.lightBlue, value: '—'),
                  _Indicator(label: 'RSI 14', color: AppTheme.green, value: '—'),
                  _Indicator(label: 'ATR 14', color: AppTheme.red, value: '—'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.label, required this.color, required this.value});
  final String label;
  final Color color;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label  $value', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      );
}

class _CandlePainter extends CustomPainter {
  _CandlePainter(this.candles);
  final List<Candle> candles;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(18, 34, size.width - 36, size.height - 75);
    final maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range = (maxPrice - minPrice).abs() < 0.000001 ? 1 : maxPrice - minPrice;
    final candleWidth = chart.width / candles.length * .62;
    final line = Paint()..strokeWidth = 1;
    for (var i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = chart.left + i * chart.width / candles.length + chart.width / candles.length / 2;
      double y(double price) => chart.bottom - ((price - minPrice) / range) * chart.height;
      final up = candle.close >= candle.open;
      line.color = up ? AppTheme.green : AppTheme.red;
      canvas.drawLine(Offset(x, y(candle.high)), Offset(x, y(candle.low)), line);
      final body = Rect.fromLTRB(x - candleWidth / 2, y(up ? candle.close : candle.open), x + candleWidth / 2, y(up ? candle.open : candle.close));
      canvas.drawRect(body, line..style = PaintingStyle.fill);
    }
    final grid = Paint()..color = AppTheme.muted.withOpacity(.12)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => oldDelegate.candles != candles;
}