# 📊 Backtest Results — 5-Min vs Daily Candles

> **Date:** June 6, 2026 | **Capital:** ₹1,00,000 | **Data:** Fyers API  
> **Stocks:** RELIANCE, TCS, INFY, HDFCBANK, SBIN (11 strategies each)

---

## 🏆 DAILY CANDLES (1-Year) — Top Performers

| Rank | Strategy | Stock | Return | Trades | Win Rate | PF | Sharpe | Rating |
|------|----------|-------|--------|--------|----------|-----|--------|--------|
| 1 | **ICT FVG** | SBIN | **+22.88%** | — | — | — | — | ⭐⭐⭐⭐⭐ EXCELLENT |
| 2 | **Bollinger Breakout** | SBIN | **+12.36%** | 8 | 62.5% | 2.38 | 6.54 | ⭐⭐⭐⭐⭐ EXCELLENT |
| 3 | **ICT OTE** | TCS | **+10.32%** | 5 | 60.0% | 5.04 | 10.43 | ⭐⭐⭐⭐⭐ EXCELLENT |
| 4 | **ICT Order Block** | HDFCBANK | **+9.57%** | 4 | 50.0% | 4.51 | 9.21 | ⭐⭐⭐⭐⭐ EXCELLENT |
| 5 | **ICT FVG** | TCS | **+8.86%** | 26 | 38.5% | 1.31 | 1.71 | ⭐⭐⭐ AVERAGE |
| 6 | **RSI Reversion** | INFY | **+8.51%** | 6 | 66.7% | 1.89 | 5.02 | ⭐⭐⭐⭐⭐ EXCELLENT |
| 7 | **ICT OTE** | HDFCBANK | **+8.05%** | 4 | 50.0% | 2.77 | 7.46 | ⭐⭐⭐⭐⭐ EXCELLENT |
| 8 | **RSI Reversion** | TCS | **+6.77%** | 7 | 57.1% | 1.79 | 4.41 | ⭐⭐⭐⭐ GOOD |
| 9 | **ICT FVG** | RELIANCE | **+6.69%** | 31 | 38.7% | 1.23 | 1.32 | ⭐⭐⭐ AVERAGE |
| 10 | **ICT OTE** | SBIN | **+6.26%** | 3 | 66.7% | 3.85 | 10.93 | ⭐⭐⭐⭐⭐ EXCELLENT |

---

## ⚡ 5-MIN CANDLES (3-Month) — Top Performers

| Rank | Strategy | Stock | Return | Trades | Win Rate | Rating |
|------|----------|-------|--------|--------|----------|--------|
| 1 | **VWAP + EMA** | TCS | **+3.39%** | 22 | 50.0% | ⭐⭐⭐ AVERAGE |
| 2 | **ICT OTE** | SBIN | **+2.80%** | 86 | 44.2% | ⭐⭐⭐ AVERAGE |
| 3 | **VWAP + EMA** | INFY | **+1.55%** | 18 | 50.0% | ⭐⭐⭐ AVERAGE |

> [!CAUTION]
> All other strategies LOSE money on 5-min candles. MACD and ICT FVG lose up to -40%.

---

## 📊 Head-to-Head: Daily vs 5-Min

| Strategy | Daily Avg Return | 5-Min Avg Return | Winner |
|----------|-----------------|------------------|--------|
| **ICT FVG** | **+7.18%** | -28.11% | 📅 Daily by far |
| **ICT OTE** | **+3.42%** | -7.70% | 📅 Daily |
| **Bollinger Breakout** | **+5.32%** | -10.74% | 📅 Daily |
| **RSI Reversion** | **+0.33%** | -11.09% | 📅 Daily |
| **ICT Order Block** | **-1.62%** | -7.88% | 📅 Daily |
| **VWAP + EMA** | **+0.53%** | **+0.39%** | 🤝 Both OK |
| **EMA Crossover** | -4.29% | -15.19% | 📅 Daily (less bad) |
| **Combo** | -4.12% | -10.03% | 📅 Daily (less bad) |
| **MACD Momentum** | -12.88% | -27.67% | ❌ Both bad |

---

## 🎯 Final Recommendations

### For Swing Trading (Daily Candles) — USE THESE:
| Strategy | Best Stock | Return | Action |
|----------|-----------|--------|--------|
| **ICT FVG** | SBIN | +22.88% | ✅ **Deploy** |
| **Bollinger Breakout** | SBIN | +12.36% | ✅ **Deploy** |
| **ICT OTE** | TCS | +10.32% | ✅ **Deploy** |
| **RSI Reversion** | INFY | +8.51% | ✅ **Deploy** |
| **ICT Order Block** | HDFCBANK | +9.57% | ✅ **Deploy** |

### For Intraday (5-Min Candles):
| Strategy | Best Stock | Return | Action |
|----------|-----------|--------|--------|
| **VWAP + EMA** | TCS | +3.39% | ⚠️ Use with caution |

### AVOID on all timeframes:
- ❌ MACD Momentum — loses everywhere
- ❌ Supertrend — generates no signals
- ❌ ICT Liquidity — generates no signals

---

> [!IMPORTANT]
> **Key insight:** Daily candles are far more profitable than 5-minute. The 5-min noise kills most strategies.
> **Best combo:** ICT FVG on SBIN (daily) + VWAP+EMA on TCS (intraday)
