class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class PaperAccount {
  const PaperAccount({
    required this.balance,
    required this.equity,
    required this.dailyPnl,
    required this.openPnl,
  });

  final double balance;
  final double equity;
  final double dailyPnl;
  final double openPnl;
}

class BotSummary {
  const BotSummary({
    required this.id,
    required this.name,
    required this.strategy,
    required this.active,
    required this.trades,
  });

  final String id;
  final String name;
  final String strategy;
  final bool active;
  final int trades;

  BotSummary copyWith({bool? active}) => BotSummary(
        id: id,
        name: name,
        strategy: strategy,
        active: active ?? this.active,
        trades: trades,
      );
}

class OpenPosition {
  const OpenPosition({
    required this.side,
    required this.bot,
    required this.entry,
    required this.pnl,
    required this.lot,
  });

  final String side;
  final String bot;
  final double entry;
  final double pnl;
  final double lot;
}