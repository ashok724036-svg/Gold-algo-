type CandleRow = { symbol: string; timeframe: string; open: number; high: number; low: number; close: number; volume: number; timestamp: string };

function fromTwelveData(value: Record<string, unknown>): CandleRow {
  const rawDatetime = String(value.datetime ?? '');
  const normalizedDatetime = rawDatetime.replace(' ', 'T');
  const hasTimezone = /(?:Z|[+-]\d{2}:\d{2})$/i.test(normalizedDatetime);
  const timestamp = new Date(hasTimezone ? normalizedDatetime : `${normalizedDatetime}Z`);
  const open = Number(value.open);
  const high = Number(value.high);
  const low = Number(value.low);
  const close = Number(value.close);
  const volume = Number(value.volume ?? 0);
  if (!Number.isFinite(timestamp.getTime()) || ![open, high, low, close, volume].every(Number.isFinite) || Math.min(open, high, low, close) <= 0) {
    throw new Error('TwelveData returned an invalid candle');
  }
  return {
    symbol: 'XAU/USD',
    timeframe: '1m',
    timestamp: timestamp.toISOString(),
    open,
    high,
    low,
    close,
    volume,
  };
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) return Response.json({ error: 'Supabase environment is incomplete' }, { status: 500 });

  const sources: Array<() => Promise<CandleRow[]>> = [
    async () => {
      const keys = [
        Deno.env.get('TWELVEDATA_API_KEY') ?? '',
        ...(Deno.env.get('TWELVEDATA_KEYS') ?? '').split(','),
      ].map((key) => key.trim()).filter(Boolean);
      if (!keys.length) throw new Error('TwelveData key is not configured');
      const key = keys[Math.floor(Date.now() / 60000) % keys.length];
      const response = await fetch(`https://api.twelvedata.com/time_series?symbol=XAU%2FUSD&interval=1min&outputsize=1&timezone=UTC&apikey=${encodeURIComponent(key)}`);
      const data = await response.json() as { values?: Array<Record<string, unknown>>; status?: string; message?: string };
      if (!response.ok || data.status === 'error') throw new Error(data.message ?? `TwelveData ${response.status}`);
      const value = data.values?.[0];
      if (!value) throw new Error('TwelveData returned no candle');
      return [fromTwelveData(value)];
    },
    async () => {
      const proxy = Deno.env.get('DUKASCOPY_PROXY_URL');
      if (!proxy) throw new Error('Dukascopy proxy is not configured');
      const response = await fetch(`${proxy}/live-candle?symbol=XAUUSD`);
      if (!response.ok) throw new Error(`Dukascopy proxy ${response.status}`);
      return await response.json();
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
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates,return=representation' },
    body: JSON.stringify(rows),
  });
  if (!result.ok) return Response.json({ error: await result.text() }, { status: 502 });
  return Response.json({ inserted: rows.length, sourceErrors: errors });
});