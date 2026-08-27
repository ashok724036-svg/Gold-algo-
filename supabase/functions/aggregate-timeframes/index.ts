const windows = [{ timeframe: '5m', minutes: 5 }, { timeframe: '15m', minutes: 15 }, { timeframe: '30m', minutes: 30 }, { timeframe: '1h', minutes: 60 }];

Deno.serve(async () => {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return Response.json({ error: 'Supabase environment is incomplete' }, { status: 500 });
  const headers = { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' };
  const latest = await fetch(`${url}/rest/v1/candles?select=*&timeframe=eq.1m&order=timestamp.desc&limit=360`, { headers });
  if (!latest.ok) return Response.json({ error: await latest.text() }, { status: 502 });
  const candles = await latest.json() as Array<{ timestamp: string; open: number; high: number; low: number; close: number; volume: number; symbol: string }>;
  const writes: unknown[] = [];
  for (const window of windows) {
    const buckets = new Map<number, typeof candles>();
    for (const candle of candles) {
      const time = new Date(candle.timestamp).getTime();
      const bucket = Math.floor(time / (window.minutes * 60_000)) * (window.minutes * 60_000);
      const list = buckets.get(bucket) ?? [];
      list.push(candle);
      buckets.set(bucket, list);
    }
    for (const [bucket, list] of buckets) {
      list.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
      writes.push({ symbol: 'XAU/USD', timeframe: window.timeframe, timestamp: new Date(bucket).toISOString(), open: list[0].open, high: Math.max(...list.map((c) => c.high)), low: Math.min(...list.map((c) => c.low)), close: list[list.length - 1].close, volume: list.reduce((sum, c) => sum + c.volume, 0) });
    }
  }
  const write = await fetch(`${url}/rest/v1/candles?on_conflict=symbol%2Ctimeframe%2Ctimestamp`, { method: 'POST', headers: { ...headers, Prefer: 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify(writes) });
  if (!write.ok) return Response.json({ error: await write.text() }, { status: 502 });
  return Response.json({ aggregated: writes.length });
});