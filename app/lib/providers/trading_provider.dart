import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trading_models.dart';
import '../services/market_data_service.dart';

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

final candlesProvider =
    StateNotifierProvider<CandlesController, CandlesState>((ref) {
  final controller = CandlesController();
  ref.onDispose(controller.dispose);
  return controller;
});

class CandlesState {
  const CandlesState({
    required this.timeframe,
    required this.candles,
    this.loading = false,
    this.live = false,
    this.error,
    this.lastUpdated,
  });

  factory CandlesState.initial() => const CandlesState(
        timeframe: 'M1',
        candles: [],
        loading: true,
      );

  final String timeframe;
  final List<Candle> candles;
  final bool loading;
  final bool live;
  final String? error;
  final DateTime? lastUpdated;
}

class CandlesController extends StateNotifier<CandlesState> {
  CandlesController() : super(CandlesState.initial()) {
    _service.onCandle = _handleRealtimeCandle;
    unawaited(load('M1'));
  }

  final MarketDataService _service = MarketDataService();
  Timer? _refreshTimer;
  int _loadGeneration = 0;

  Future<void> load(String timeframe) async {
    final generation = ++_loadGeneration;
    final apiTimeframe = _apiTimeframe(timeframe);
    _refreshTimer?.cancel();
    state = CandlesState(
      timeframe: timeframe,
      candles: state.timeframe == timeframe ? state.candles : const [],
      loading: true,
      live: state.live,
      lastUpdated: state.lastUpdated,
    );

    String? refreshWarning;
    if (_service.isConfigured) {
      try {
        await _service.refreshLiveCandle();
      } catch (_) {
        refreshWarning = 'Live refresh is not available yet.';
      }
    }

    try {
      final result = await _service.load(apiTimeframe);
      if (generation != _loadGeneration) return;
      state = CandlesState(
        timeframe: timeframe,
        candles: result.candles,
        loading: false,
        live: _service.isConfigured && !result.fromCache,
        error: result.warning ?? refreshWarning,
        lastUpdated: result.candles.isEmpty ? null : DateTime.now(),
      );
      if (_service.isConfigured) _startRefreshTimer();
    } catch (_) {
      state = CandlesState(
        timeframe: timeframe,
        candles: const [],
        loading: false,
        live: false,
        error: 'Could not load candles. Apply the Supabase migration first.',
      );
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final timeframe = state.timeframe;
      try {
        await _service.refreshLiveCandle();
        final result = await _service.load(_apiTimeframe(timeframe));
        if (timeframe != state.timeframe) return;
        state = CandlesState(
          timeframe: state.timeframe,
          candles: result.candles,
          loading: false,
          live: !result.fromCache,
          error: result.warning,
          lastUpdated: result.candles.isEmpty ? state.lastUpdated : DateTime.now(),
        );
      } catch (_) {
        state = CandlesState(
          timeframe: state.timeframe,
          candles: state.candles,
          loading: false,
          live: false,
          error: 'Live refresh failed. Retrying in one minute.',
          lastUpdated: state.lastUpdated,
        );
      }
    });
  }

  void _handleRealtimeCandle(MarketCandleEvent event) {
    if (event.timeframe != _apiTimeframe(state.timeframe)) return;
    final candles = [
      ...state.candles.where((item) => item.time != event.candle.time),
      event.candle,
    ]..sort((a, b) => a.time.compareTo(b.time));
    state = CandlesState(
      timeframe: state.timeframe,
      candles: candles.length > 200 ? candles.sublist(candles.length - 200) : candles,
      loading: false,
      live: true,
      lastUpdated: DateTime.now(),
    );
  }

  String _apiTimeframe(String label) {
    return switch (label) {
      'M1' => '1m',
      'M5' => '5m',
      'M15' => '15m',
      'M30' => '30m',
      'H1' => '1h',
      _ => '1m',
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    unawaited(_service.dispose());
    super.dispose();
  }
}

final demoCandlesProvider = Provider<List<Candle>>((ref) {
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