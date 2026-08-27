import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trading_models.dart';

final selectedNavProvider = StateProvider<int>((ref) => 0);
final selectedTimeframeProvider = StateProvider<String>((ref) => 'M1');
final isHindiProvider = StateProvider<bool>((ref) => false);

final accountProvider = Provider<PaperAccount>((ref) {
  return const PaperAccount(
    balance: 10000,
    equity: 10184.60,
    dailyPnl: 184.60,
    openPnl: 42.80,
  );
});

final botsProvider =
    StateNotifierProvider<BotsController, List<BotSummary>>((ref) {
  return BotsController();
});

final candlesProvider = Provider<List<Candle>>((ref) {
  final random = Random(7);
  var price = 2342.6;
  return List.generate(54, (index) {
    final open = price;
    final move = (random.nextDouble() - .46) * 5.4;
    final close = open + move;
    final high = max(open, close) + random.nextDouble() * 2.1;
    final low = min(open, close) - random.nextDouble() * 2.1;
    price = close;
    return Candle(
      time: DateTime.now().subtract(Duration(minutes: 54 - index)),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: 80 + random.nextDouble() * 260,
    );
  });
});

final positionsProvider = Provider<List<OpenPosition>>((ref) {
  return const [
    OpenPosition(
      side: 'BUY',
      bot: 'EMA Cross Scalper V3',
      entry: 2340.82,
      pnl: 42.8,
      lot: .12,
    ),
  ];
});

class BotsController extends StateNotifier<List<BotSummary>> {
  BotsController()
      : super(const [
          BotSummary(
            id: 'ema-v3',
            name: 'EMA Cross Scalper V3',
            strategy: 'EMA 9/21 + ATR filter',
            active: true,
            trades: 128,
          ),
          BotSummary(
            id: 'rsi-bb-v3',
            name: 'RSI + Bollinger Scalper V3',
            strategy: 'Mean reversion',
            active: false,
            trades: 74,
          ),
          BotSummary(
            id: 'snr-ict-lite',
            name: 'SNR Momentum / ICT Lite',
            strategy: 'Structure + FVG',
            active: false,
            trades: 51,
          ),
          BotSummary(
            id: 'm1-hft',
            name: 'M1 High-Frequency Scalper',
            strategy: 'Engulfing + momentum',
            active: false,
            trades: 202,
          ),
        ]);

  void toggle(String id) {
    state = [
      for (final bot in state)
        if (bot.id == id) bot.copyWith(active: !bot.active) else bot,
    ];
  }
}