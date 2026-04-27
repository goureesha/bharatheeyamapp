# Firestore Usage & Cost Analysis — 2000 Users

## Firestore Services in Bharatheeyam App

Your app uses Firestore in **4 places**:

| # | Service | Collection | Operations |
|---|---------|-----------|------------|
| 1 | Device Binding | `device_bindings/{email}` | Read + Write on every app launch |
| 2 | Cloud Sync | `user_data/{email}` | 1 write/day (auto), manual upload/download |
| 3 | Tester Service | `testers/{email}` | 1 read per sign-in |
| 4 | Appointment Listener | `appointments/{email}/requests` | Real-time snapshot listener |

---

## Per-User Daily Operations

### 1. Device Binding (~8 reads, ~3 writes/day)
- **App opens** ~3 times/day average
  - Each open: 1 read (`checkBinding`) + 1 write (`update lastSeen`) = 2 ops
- **App resume** events: ~5/day
  - Each resume: 1 read (`checkBinding`) = 1 read
- **First-time bind**: 1 write (one-time only)
- **Daily total**: ~8 reads + 3 writes

### 2. Cloud Sync (~0.2 reads, ~1.2 writes/day)
- **Auto-sync**: 1 write/day (if >24h since last)
- **Manual sync**: ~1 upload per 5 days = 0.2 writes/day
- **Manual download**: rare, ~0.1 reads/day
- **Daily total**: ~0.2 reads + 1.2 writes

### 3. Tester Service (~1 read/day)
- **On sign-in**: 1 read from `testers/{email}`
- **Silent sign-in on launch**: triggers once per app cold start (~1/day)
- **Daily total**: ~1 read

### 4. Appointment Listener (~3 reads/day)
- **Snapshot listener**: 1 initial read on app start
- **Ongoing**: reads only count when new docs arrive (rare for most users)
- **Daily total**: ~3 reads (3 app opens × 1 initial snapshot)

### Per-User Daily Summary

| Operation | Count |
|-----------|-------|
| **Reads** | ~12/day |
| **Writes** | ~4.2/day |
| **Deletes** | ~0/day |

---

## 2000 Users — Daily & Monthly Totals

| Metric | Per Day | Per Month (30d) |
|--------|---------|-----------------|
| **Reads** | 24,000 | 720,000 |
| **Writes** | 8,400 | 252,000 |
| **Deletes** | ~0 | ~0 |

---

## Storage Estimate

| Data | Size per User | Total (2000 users) |
|------|--------------|-------------------|
| `device_bindings/{email}` | ~200 bytes | 400 KB |
| `user_data/{email}` (backup) | ~10-100 KB | 200 MB (worst case) |
| `user_data/{email}/chunks/*` | ~0-500 KB (large users) | 100 MB |
| `testers/{email}` | ~100 bytes | negligible |
| `appointments/{email}/requests/*` | ~500 bytes each | ~10 MB |
| **Total Storage** | | **~310 MB** |

---

## Firebase Free Tier (Spark Plan) Limits

| Resource | Free Limit | Your Usage | Status |
|----------|-----------|------------|--------|
| Reads/day | **50,000** | 24,000 | ✅ **48% used** |
| Writes/day | **20,000** | 8,400 | ✅ **42% used** |
| Deletes/day | **20,000** | ~0 | ✅ |
| Storage | **1 GiB** | ~310 MB | ✅ **30% used** |
| Network egress | **10 GiB/month** | ~5 GB | ✅ |

> [!TIP]
> **2000 users fits comfortably within the FREE Spark plan.** You won't pay anything for Firestore at this scale.

---

## When Would You Need to Pay? (Blaze Plan)

If usage grows beyond the free tier:

| Users | Reads/day | Writes/day | Fits Free Tier? |
|-------|-----------|------------|-----------------|
| 2,000 | 24,000 | 8,400 | ✅ Yes |
| 4,000 | 48,000 | 16,800 | ⚠️ Barely |
| 5,000 | 60,000 | 21,000 | ❌ Exceeds writes |
| 10,000 | 120,000 | 42,000 | ❌ Exceeds both |

### Blaze Plan Pricing (pay-as-you-go, after free quota):

| Operation | Price |
|-----------|-------|
| Reads | ₹5 per 100K reads (~$0.06) |
| Writes | ₹15 per 100K writes (~$0.18) |
| Deletes | ₹1.7 per 100K deletes (~$0.02) |
| Storage | ₹15/GiB/month (~$0.18) |

### Cost at 10,000 users (Blaze):
- Reads: 360K/day × 30 = 10.8M/month → ~₹540/month
- Writes: 42K/day × 30 = 1.26M/month → ~₹189/month  
- Storage: ~1.5 GB → ~₹23/month
- **Total: ~₹750/month ($9)**

---

## Optimization Tips (If You Scale Beyond Free Tier)

1. **Reduce resume binding checks** — Cache binding result for 1 hour instead of checking on every resume
2. **Batch writes** — Combine `lastSeen` update with cloud sync write
3. **Increase auto-sync interval** — Move from 24h to 48h
4. **Remove `lastSeen` updates** — The `lastSeen` field in device_bindings causes 1 write per app open; you could skip it since binding check (read) is sufficient

> [!IMPORTANT]
> **Bottom line: At 2000 users, Firestore is completely FREE. You can safely scale to ~4000 users before needing the Blaze plan, and even at 10K users the cost is only ~₹750/month.**
