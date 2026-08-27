import { indicators, type Candle } from '../_shared/indicators.ts';

type Bot = { id: string; user_id: string; name: string; language: string; code_content: string; parameters: Record<string, unknown>; magic_number: number };
type Action = { action: 'BUY' | 'SELL' | 'HOLD' | 'CLOSE'; sl?: number; tp?: number; lot?: number; comment?: string };

function evaluateJsonStrategy(code: string, candle: Candle, values: ReturnType<typeof indicators>): Action {
  const parsed = JSON.parse(code) as { rules?: Array<{ if: string; action: Action['action']; sl?: string; tp?: string }> };
  for (const rule of parsed.rules ?? []) {
    const expression = rule.if
      .replace(/\bema9\b/g, String(values.ema9)).replace(/\bema21\b/g, String(values.ema21))
      .replace(/\brsi\b/g, String(values.rsi)).replace(/\bclose\b/g, String(candle.close))
      .replace(/\bbb_lower\b/g, String(values.bb_lower)).replace(/\bbb_upper\b/g, String(values.bb_upper));
    const match = expression.match(/^(-?[\d.]+)\s*(<|>|<=|>=|==)\s*(-?[\d.]+)$/);
    const truthy = match ? ({ '<': Number(match[1]) < Number(match[3]), '>': Number(match[1]) > Number(match[3]), '<=': Number(match[1]) <= Number(match[3]), '>=': Number(match[1]) >= Number(match[3]), '==': Number(match[1]) === Number(match[3]) } as Record<string, boolean>)[match[2]] : false;
    if (truthy) return { action: rule.action, comment: `Rule matched: ${rule.if}` };
  }
  return { action: 'HOLD' };
}

Deno.serve(async () => {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return Response.json({ error: 'Supabase environment is incomplete' }, { status: 500 });
  const headers = { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' };
  const candleResponse = await fetch(`${url}/rest/v1/candles?select=*&timeframe=eq.1m&order=timestamp.desc&limit=100`, { headers });
  const botsResponse = await fetch(`${url}/rest/v1/bots?select=*&is_active=eq.true`, { headers });
  if (!candleResponse.ok || !botsResponse.ok) return Response.json({ error: 'Unable to load execution inputs' }, { status: 502 });
  const candles = (await candleResponse.json() as Candle[]).reverse();
  const bots = await botsResponse.json() as Bot[];
  const candle = candles.at(-1);
  if (!candle || candles.length < 22) return Response.json({ executed: 0, reason: 'Waiting for indicator history' });
  const values = indicators(candles);
  const logs: unknown[] = [];
  let executed = 0;
  for (const bot of bots) {
    let action: Action = { action: 'HOLD' };
    try {
      if (bot.language === 'json_strategy') action = evaluateJsonStrategy(bot.code_content, candle, values);
      else action = { action: 'HOLD', comment: 'Python strategies are backtest-only; upload a JSON live strategy.' };
    } catch (error) {
      action = { action: 'HOLD', comment: `Strategy rejected: ${error instanceof Error ? error.message : String(error)}` };
    }
    logs.push({ bot_id: bot.id, level: action.action === 'HOLD' ? 'INFO' : 'SIGNAL', message: action.comment ?? action.action, candle_timestamp: candle.timestamp });
    if (action.action === 'BUY' || action.action === 'SELL') {
      const spread = 0.30 + Math.random() * 0.20;
      const slippage = 0.05 + Math.random() * 0.10;
      const entry = action.action === 'BUY' ? candle.close + spread / 2 + slippage : candle.close - spread / 2 - slippage;
      const lot = Math.min(Number(action.lot ?? bot.parameters.lot_size ?? 0.1), Number(bot.parameters.max_lot_size ?? 1));
      const stop = values.atr * Number(action.sl ? String(action.sl).replace('atr', '') : 1);
      const target = values.atr * Number(action.tp ? String(action.tp).replace('atr', '') : 1.5);
      await fetch(`${url}/rest/v1/paper_trades`, { method: 'POST', headers: { ...headers, Prefer: 'return=minimal' }, body: JSON.stringify({ user_id: bot.user_id, bot_id: bot.id, symbol: 'XAU/USD', side: action.action, entry_price: entry, sl: action.action === 'BUY' ? entry - stop : entry + stop, tp: action.action === 'BUY' ? entry + target : entry - target, lot_size: lot, status: 'OPEN', magic_number: bot.magic_number, comment: action.comment ?? 'Signal' }) });
      executed++;
    }
  }
  if (logs.length) await fetch(`${url}/rest/v1/bot_logs`, { method: 'POST', headers, body: JSON.stringify(logs) });
  return Response.json({ executed, bots: bots.length, candle: candle.timestamp });
});