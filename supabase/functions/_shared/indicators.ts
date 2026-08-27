export type Candle = { open: number; high: number; low: number; close: number; volume: number; timestamp: string };

export function ema(values: number[], period: number): number {
  if (!values.length) return 0;
  const multiplier = 2 / (period + 1);
  let result = values[0];
  for (const value of values.slice(1)) result = (value - result) * multiplier + result;
  return result;
}

export function indicators(candles: Candle[]) {
  const closes = candles.map((c) => c.close);
  const recent = candles.slice(-14);
  const changes = recent.slice(1).map((c, i) => c.close - recent[i].close);
  const gains = changes.filter((v) => v > 0).reduce((a, b) => a + b, 0) / 14;
  const losses = Math.abs(changes.filter((v) => v < 0).reduce((a, b) => a + b, 0)) / 14;
  const rsi = losses === 0 ? 100 : 100 - 100 / (1 + gains / losses);
  const atr = recent.reduce((sum, c, i) => {
    const previous = i === 0 ? c.close : recent[i - 1].close;
    return sum + Math.max(c.high - c.low, Math.abs(c.high - previous), Math.abs(c.low - previous));
  }, 0) / Math.max(recent.length, 1);
  const last20 = closes.slice(-20);
  const mean = last20.reduce((a, b) => a + b, 0) / Math.max(last20.length, 1);
  const deviation = Math.sqrt(last20.reduce((s, v) => s + (v - mean) ** 2, 0) / Math.max(last20.length, 1));
  return { ema9: ema(closes.slice(-50), 9), ema21: ema(closes.slice(-100), 21), ema50: ema(closes, 50), rsi, atr, bb_upper: mean + deviation * 2, bb_lower: mean - deviation * 2 };
}