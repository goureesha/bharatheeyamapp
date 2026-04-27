# Trading Strategy Scanner & Backtester — Project Plan

> **Status:** SAVED FOR LATER — Start after Bharatheeyam astrology app is complete.

---

## User Requirements (Confirmed)

| Parameter | Decision |
|---|---|
| **Instruments** | Nifty 500 stocks |
| **Intraday Timeframe** | 5-minute candles |
| **Swing Timeframe** | 15-minute candles |
| **Data API** | Fyers API (user has access) |
| **Broker API** | Fyers (for live paper trading in Phase 2) |

---

## What We're Building

A Python-based automated tool that:
1. **Fetches data** from Fyers API for all Nifty 500 stocks
2. **Scans 15+ technical strategies** (EMA, RSI, MACD, Supertrend, VWAP, ORB, Bollinger, etc.)
3. **Backtests each strategy** with realistic brokerage fees & slippage
4. **Ranks strategies** by Sharpe Ratio, Win Rate, Max Drawdown, Profit Factor
5. **Generates visual HTML reports** with equity curves & trade logs
6. **Phase 2:** Runs top strategy live via Fyers API (paper trading first)
7. **Dashboard:** Streamlit UI for monitoring signals & P&L

## Tech Stack
- Python 3.11+
- Fyers API (data + execution)
- backtesting.py / vectorbt (backtest engine)
- pandas-ta (130+ indicators)
- Streamlit (dashboard)
- plotly (interactive charts)

## Strategies to Test
1. EMA Crossover (9/21)
2. RSI Reversal
3. MACD Signal
4. Bollinger Breakout
5. Supertrend
6. VWAP Pullback
7. Opening Range Breakout (ORB)
8. Stochastic Crossover
9. ADX Trend
10. Ichimoku Cloud
11. Donchian Breakout
12. ATR Trailing Stop
13. RSI + MACD Combo
14. Volume Spike
15. Pivot Point S/R

## Notes
- Fyers API docs: https://docs.fyers.in/
- Nifty 500 list can be fetched from NSE website
- Need to handle rate limits on Fyers API when scanning 500 stocks
- Walk-forward testing to avoid overfitting
