insert into public.bots (user_id, name, description, language, code_content, parameters, magic_number)
select id, 'EMA Cross Scalper V3', 'EMA 9/21 crossover with ATR volatility filter.', 'json_strategy',
  '{"rules":[{"if":"ema9 > ema21 and close > ema9","action":"BUY","sl":"atr1.0","tp":"atr1.5"},{"if":"ema9 < ema21 and close < ema9","action":"SELL","sl":"atr1.0","tp":"atr1.5"}]}',
  '{"lot_size":0.1,"risk_percent":1,"atr_multiplier":1.0,"session_filter":true}', 9001
from public.profiles limit 1
on conflict do nothing;

insert into public.bots (user_id, name, description, language, code_content, parameters, magic_number)
select id, 'RSI + Bollinger Scalper V3', 'Mean reversion when RSI confirms a band touch.', 'json_strategy',
  '{"rules":[{"if":"rsi < 30 and close < bb_lower","action":"BUY","sl":"atr1.0","tp":"atr1.5"},{"if":"rsi > 70 and close > bb_upper","action":"SELL","sl":"atr1.0","tp":"atr1.5"}]}',
  '{"lot_size":0.1,"risk_percent":1,"rsi_low":30,"rsi_high":70}', 9002
from public.profiles limit 1
on conflict do nothing;

insert into public.bots (user_id, name, description, language, code_content, parameters, magic_number)
select id, 'SNR Momentum / ICT Lite', 'Structure breaks with a lightweight fair-value-gap check.', 'json_strategy',
  '{"rules":[{"if":"close > previous_high and volume > volume_avg","action":"BUY","sl":"atr1.2","tp":"atr2.0"},{"if":"close < previous_low and volume > volume_avg","action":"SELL","sl":"atr1.2","tp":"atr2.0"}]}',
  '{"lot_size":0.1,"risk_percent":1}', 9003
from public.profiles limit 1
on conflict do nothing;

insert into public.bots (user_id, name, description, language, code_content, parameters, magic_number)
select id, 'M1 High-Frequency Scalper', 'Engulfing candle plus short-term momentum.', 'json_strategy',
  '{"rules":[{"if":"bullish_engulfing and rsi > 45 and rsi < 68","action":"BUY","sl":"atr0.8","tp":"atr1.2"},{"if":"bearish_engulfing and rsi < 55 and rsi > 32","action":"SELL","sl":"atr0.8","tp":"atr1.2"}]}',
  '{"lot_size":0.05,"risk_percent":0.5}', 9004
from public.profiles limit 1
on conflict do nothing;