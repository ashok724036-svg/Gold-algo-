import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/trading_models.dart';
import '../storage/local_cache.dart';

class MarketDataResult {
  const MarketDataResult({
    required this.candles,
    required this.fromCache,
    this.warning,
  });

  final List<Candle> candles;
  final bool fromCache;
  final String? warning;
}

class MarketCandleEvent {
  const MarketCandleEvent(this.timeframe, this.candle);

  final String timeframe;
  final Candle candle;
}

class MarketDataService {
  MarketDataService() : _cache = LocalCache() {
    final client = AppConfig.supabase;
    if (client == null) return;

    _channel = client
        .channel('goldscalper-candles')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'candles',
          callback: (payload) {
            final record = payload.newRecord;
            final timeframe = record['timeframe']?.toString();
            final candle = _parseCandle(record);
            if (timeframe != null && candle != null) {
              onCandle?.call(MarketCandleEvent(timeframe, candle));
            }
          },
        )
        .subscribe();
  }

  final LocalCache _cache;
  RealtimeChannel? _channel;
  void Function(MarketCandleEvent event)? onCandle;

  bool get isConfigured => AppConfig.supabase != null;

  Future<MarketDataResult> load(String timeframe, {int limit = 200}) async {
    final client = AppConfig.supabase;
    final cached = await _readCache(timeframe, limit: limit);

    if (client == null) {
      return MarketDataResult(candles: cached, fromCache: true);
    }

    try {
      final response = await client
          .from('candles')
          .select('symbol,timeframe,open,high,low,close,volume,timestamp')
          .eq('symbol', 'XAU/USD')
          .eq('timeframe', timeframe)
          .order('timestamp', ascending: false)
          .limit(limit);
      final candles = _parseRows(response).reversed.toList(growable: false);
      if (candles.isNotEmpty) {
        await _saveCache(timeframe, candles);
        return MarketDataResult(candles: candles, fromCache: false);
      }
      if (cached.isNotEmpty) {
        return MarketDataResult(
          candles: cached,
          fromCache: true,
          warning: 'Supabase returned no candles for this timeframe.',
        );
      }
      return const MarketDataResult(
        candles: [],
        fromCache: false,
        warning: 'No candles are available yet.',
      );
    } catch (_) {
      if (cached.isNotEmpty) {
        return MarketDataResult(
          candles: cached,
          fromCache: true,
          warning: 'Live sync is unavailable. Showing the last cached candles.',
        );
      }
      rethrow;
    }
  }

  Future<void> refreshLiveCandle() async {
    final client = AppConfig.supabase;
    if (client == null) return;

    final response = await client.functions.invoke(
      'fetch-xau-candles',
      body: <String, dynamic>{},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Live candle refresh failed.');
    }
  }

  Future<List<Candle>> _readCache(String timeframe, {required int limit}) async {
    final rows = await _cache.recentCandles(timeframe, limit: limit);
    return rows
        .map(
          (row) => Candle(
            time: row.timestamp.toUtc(),
            open: row.open,
            high: row.high,
            low: row.low,
            close: row.close,
            volume: row.volume,
          ),
        )
        .toList()
        .reversed
        .toList(growable: false);
  }

  Future<void> _saveCache(String timeframe, Iterable<Candle> candles) async {
    await _cache.saveCandles(
      candles.map(
        (candle) => CachedCandlesCompanion.insert(
          symbol: 'XAU/USD',
          timeframe: timeframe,
          timestamp: candle.time.toUtc(),
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
          volume: candle.volume,
        ),
      ),
    );
    await _cache.prune();
  }

  List<Candle> _parseRows(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => _parseCandle(Map<String, dynamic>.from(row)))
        .whereType<Candle>()
        .toList(growable: false);
  }

  Candle? _parseCandle(Map<String, dynamic> row) {
    final time = DateTime.tryParse(row['timestamp']?.toString() ?? '');
    final open = _number(row['open']);
    final high = _number(row['high']);
    final low = _number(row['low']);
    final close = _number(row['close']);
    final volume = _number(row['volume']) ?? 0;
    if (time == null ||
        open == null ||
        high == null ||
        low == null ||
        close == null ||
        open <= 0 ||
        high <= 0 ||
        low <= 0 ||
        close <= 0) {
      return null;
    }
    return Candle(
      time: time.toUtc(),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
    );
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    onCandle = null;
    if (channel != null) {
      await AppConfig.supabase?.removeChannel(channel);
    }
    await _cache.close();
  }
}