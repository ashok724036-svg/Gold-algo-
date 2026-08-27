const BINANCE_URL = 'https://api.binance.com/api/v3/klines?symbol=PAXGUSDT&interval=1m&limit=2';

type CandleRow = { symbol: string; timeframe: string; open: number; high: number; low: number; close: number; volume: number; timestamp: string };

function fromBinance(row: unknown[]): CandleRow {
  return {
    symbol: 'XAU/USD',
    timeframe: '1m',
    timestamp: new Date(Number(row[0])).toISOString(),
    open: Number(row[1]),
    high: Number(row[2]),
    low: Number(row[3]),
    close: Number(row[4]),
    volume: Number(row[5]),
  };
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) return Response.json({ error: 'Supabase environment is incomplete' }, { status: 500 });

  const sources: Array<() => Promise<CandleRow[]>> = [
    async () => {
      const proxy = Deno.env.get('DUKASCOPY_PROXY_URL');
      if (!proxy) throw new Error('Dukascopy proxy is not configured');
      const response = await fetch(`${proxy}/live-candle?symbol=XAUUSD`);
      if (!response.ok) throw new Error(`Dukascopy proxy ${response.status}`);
      return await response.json();
    },
    async () => {
      const response = await fetch(BINANCE_URL);
      if (!response.ok) throw new Error(`Binance ${response.status}`);
      const rows = await response.json() as unknown[][];
      return rows.slice(-1).map(fromBinance);
    },
    async () => {
      const keys = (Deno.env.get('TWELVEDATA_KEYS') ?? '').split(',').map((key) => key.trim()).filter(Boolean);
      if (!keys.length) throw new Error('TwelveData keys are not configured');
      const key = keys[Math.floor(Date.now() / 60000) % keys.length];
      const response = await fetch(`https://api.twelvedata.com/time_series?symbol=XAU/USD&interval=1min&outputsize=1&apikey=${encodeURIComponent(key)}`);
      if (!response.ok) throw new Error(`TwelveData ${response.status}`);
      const data = await response.json();
      const value = data.values?.[0];
      if (!value) throw new Error(data.message ?? 'TwelveData returned no candle');
      return [{ symbol: 'XAU/USD', timeframe: '1m', timestamp: new Date(value.datetime).toISOString(), open: Number(value.open), high: Number(value.high), low: Number(value.low), close: Number(value.close), volume: Number(value.volume ?? 0) }];
    },
  ];

  let rows: CandleRow[] = [];
  const errors: string[] = [];
  for (const source of sources) {
    try { rows = await source(); break; } catch (error) { errors.push(error instanceof Error ? error.message : String(error)); }
  }
  if (!rows.length) return Response.json({ error: 'All market data sources failed', details: errors }, { status: 502 });

  const result = await fetch(`${supabaseUrl}/rest/v1/candles?on_conflict=symbol%2Ctimeframe%2Ctimestamp`, {
    method: 'POST',
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, 'Content-Type': 'application/json', Prefer: 'resolution=ignore-duplicates,return=representation' },
    body: JSON.stringify(rows),
  });
  if (!result.ok) return Response.json({ error: await result.text() }, { status: 502 });
  return Response.json({ inserted: rows.length, sourceErrors: errors });
});