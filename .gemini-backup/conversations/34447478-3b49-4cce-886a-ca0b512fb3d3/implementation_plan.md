# ORB Scanner Cloud Architecture

## Goal
Cloud-based ORB scanner that runs all day, accessible from mobile, with Telegram alerts.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Mobile      │     │  Render.com      │     │  Telegram    │
│  Browser     │────▶│  (Free Cloud)    │────▶│  Bot         │
│  (Website)   │     │                  │     │  (Alerts)    │
│              │◀────│  Flask API +     │     │              │
│  GitHub      │     │  ORB Scanner     │     │  📱 Your     │
│  Pages       │     │  Background Job  │     │  Phone       │
└──────────────┘     └──────────────────┘     └──────────────┘
```

## Daily Flow
1. **9:00 AM** — Open website on phone → paste Fyers auth URL → click "Start Scan"
2. **9:15 AM** — Scanner detects ORB (first 15 min high/low)
3. **9:30 AM+** — Scanner checks breakouts every 5 minutes
4. **On signal** — Telegram sends: "🟢 BUY NIFTY50 @ 23184 | SL: 23070 | Target: 23413"
5. **On SL/Target** — Telegram sends: "🎯 TARGET HIT NIFTY50 +228 pts"
6. **3:15 PM** — Scanner closes all trades, sends daily P&L summary
7. **3:30 PM** — Scanner stops automatically

## Components

### 1. Backend (Render.com - Free)
- **Flask API** with endpoints:
  - `POST /login` — Accepts Fyers redirect URL, generates token
  - `GET /status` — Returns live scan results as JSON
  - `POST /start` — Starts background scanner
  - `GET /` — Serves the dashboard HTML
- **Background scanner thread**:
  - Runs every 5 min from 9:15 to 3:30
  - Fetches 5m data from Fyers API
  - Runs filtered ORB detection
  - Sends Telegram alerts on state changes
- **Filters applied**: VWAP trend + volume + time (before 12 PM)

### 2. Frontend (served by Render)
- Mobile-responsive dark dashboard
- Login form → paste Fyers URL
- Live signal cards (auto-refresh every 30s)
- Daily P&L summary

### 3. Telegram Bot
- Created via @BotFather
- Sends alerts for: Entry, SL Hit, Target Hit, Close@3:15
- Daily morning summary + EOD P&L

## Tech Stack
- Python Flask + gunicorn
- APScheduler (background jobs)
- python-telegram-bot
- Fyers API (direct, no CORS issues on server)
- Deployed on Render.com (free tier)

## Open Questions

> [!IMPORTANT]
> 1. Do you have a Telegram bot? If not, I'll guide you to create one via @BotFather (takes 1 minute)
> 2. Render.com free tier sleeps after 15 min inactivity. We can use a keep-alive ping to prevent this. OK?

## Verification
- Test login flow from mobile browser
- Verify Telegram alerts fire on signal changes
- Confirm scanner runs until 3:30 PM
- Check filtered ORB matches backtest results
