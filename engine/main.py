from datetime import datetime, timedelta, timezone
from math import sqrt
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="GoldScalper Pro backtest engine", version="1.0.0")


class BacktestRequest(BaseModel):
    strategy: dict[str, Any]
    candles: list[dict[str, Any]] = Field(default_factory=list)
    initial_balance: float = 10000
    lot_size: float = 0.1


def ema(values: list[float], period: int) -> float:
    result = values[0]
    multiplier = 2 / (period + 1)
    for value in values[1:]:
        result = (value - result) * multiplier + result
    return result


def action_for(strategy: dict[str, Any], candle: dict[str, Any], history: list[dict[str, Any]]) -> str:
    closes = [float(c["close"]) for c in history]
    values = {"close": closes[-1], "ema9": ema(closes[-50:], 9), "ema21": ema(closes[-100:], 21)}
    for rule in strategy.get("rules", []):
        expression = str(rule.get("if", ""))
        if "ema9 > ema21" in expression and values["ema9"] > values["ema21"]:
            return str(rule.get("action", "HOLD"))
        if "ema9 < ema21" in expression and values["ema9"] < values["ema21"]:
            return str(rule.get("action", "HOLD"))
    return "HOLD"


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "mode": "paper-only"}


@app.get("/live-candle")
async def live_candle(symbol: str = "XAUUSD") -> list[dict[str, Any]]:
    """Optional Dukascopy proxy. The free public endpoint is used only as a
    data source; no order or account operation exists in this service."""
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    url = "https://datafeed.dukascopy.com/datafeed/XAUUSD/1MN"  # public feed probe
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            response = await client.get(url, params={"time": int(now.timestamp() * 1000)})
            response.raise_for_status()
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"live feed unavailable: {exc}") from exc
    # Dukascopy binary parsing belongs in the worker deployment. Returning an
    # explicit error avoids pretending an unreadable payload is a candle.
    raise HTTPException(status_code=502, detail="feed payload requires the Dukascopy binary decoder")


@app.post("/backtest")
def backtest(request: BacktestRequest) -> dict[str, Any]:
    candles = request.candles
    if len(candles) < 22:
        raise HTTPException(status_code=422, detail="At least 22 candles are required")
    balance = request.initial_balance
    equity_curve = [balance]
    trades: list[dict[str, Any]] = []
    position: dict[str, Any] | None = None
    for index in range(21, len(candles)):
        candle = candles[index]
        action = action_for(request.strategy, candle, candles[: index + 1])
        if position and ((position["side"] == "BUY" and action == "SELL") or (position["side"] == "SELL" and action == "BUY")):
            exit_price = float(candle["close"])
            direction = 1 if position["side"] == "BUY" else -1
            pnl = (exit_price - position["entry"]) * direction * request.lot_size * 100
            balance += pnl
            trades.append({**position, "exit": exit_price, "pnl": round(pnl, 2), "closed_at": candle["timestamp"]})
            position = None
        if position is None and action in ("BUY", "SELL"):
            position = {"side": action, "entry": float(candle["close"]), "opened_at": candle["timestamp"]}
        floating = 0
        if position:
            direction = 1 if position["side"] == "BUY" else -1
            floating = (float(candle["close"]) - position["entry"]) * direction * request.lot_size * 100
        equity_curve.append(round(balance + floating, 2))
    if position:
        exit_price = float(candles[-1]["close"])
        direction = 1 if position["side"] == "BUY" else -1
        pnl = (exit_price - position["entry"]) * direction * request.lot_size * 100
        balance += pnl
        trades.append({**position, "exit": exit_price, "pnl": round(pnl, 2), "closed_at": candles[-1]["timestamp"]})
    wins = [trade for trade in trades if trade["pnl"] > 0]
    losses = [trade for trade in trades if trade["pnl"] < 0]
    gross_profit = sum(trade["pnl"] for trade in wins)
    gross_loss = abs(sum(trade["pnl"] for trade in losses))
    peak = request.initial_balance
    max_drawdown = 0
    for value in equity_curve:
        peak = max(peak, value)
        max_drawdown = max(max_drawdown, peak - value)
    returns = [equity_curve[i] - equity_curve[i - 1] for i in range(1, len(equity_curve))]
    mean = sum(returns) / max(len(returns), 1)
    deviation = sqrt(sum((value - mean) ** 2 for value in returns) / max(len(returns), 1))
    return {
        "initial_balance": request.initial_balance,
        "final_balance": round(balance, 2),
        "net_pnl": round(balance - request.initial_balance, 2),
        "total_trades": len(trades),
        "win_rate": round(len(wins) / len(trades) * 100, 2) if trades else 0,
        "profit_factor": round(gross_profit / gross_loss, 2) if gross_loss else None,
        "max_drawdown": round(max_drawdown, 2),
        "sharpe": round(mean / deviation * sqrt(252), 2) if deviation else 0,
        "equity_curve": equity_curve,
        "trades": trades,
    }