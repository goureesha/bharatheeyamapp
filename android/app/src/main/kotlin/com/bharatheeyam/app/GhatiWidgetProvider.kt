package com.bharatheeyam.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.Calendar
import kotlin.math.*

class GhatiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            update(context, appWidgetManager, id)
        }
        scheduleAlarm(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, GhatiWidgetProvider::class.java))
            for (id in ids) update(context, mgr, id)
            scheduleAlarm(context)
        }
    }

    companion object {
        const val ACTION_TICK = "com.bharatheeyam.GHATI_TICK"
        private const val PREFS   = "FlutterSharedPreferences"
        private const val KEY_SR  = "flutter.sunrise_hour24"
        private const val KEY_LG  = "flutter.lagna_rashi_index"
        private const val SIZE    = 300   // bitmap px — 300×300 ARGB = 360 KB, safe under IPC limit

        // 12 rashi colours
        private val RASHI_COL = intArrayOf(
            0xFFE74C3C.toInt(), 0xFF27AE60.toInt(), 0xFF3498DB.toInt(), 0xFF8E44AD.toInt(),
            0xFFE67E22.toInt(), 0xFF2ECC71.toInt(), 0xFF2980B9.toInt(), 0xFF9B59B6.toInt(),
            0xFFD35400.toInt(), 0xFF1ABC9C.toInt(), 0xFF2471A3.toInt(), 0xFF7D3C98.toInt()
        )
        // Short Kannada rashi labels
        private val RASHI_LBL = arrayOf(
            "\u0CAE\u0CC7", "\u0CB5\u0CC3", "\u0CAE\u0CBF", "\u0C95",
            "\u0CB8\u0CBF", "\u0C95\u0CA8\u0CCD", "\u0CA4\u0CC1", "\u0CB5\u0CC3\u0C9A\u0CCD",
            "\u0CA7", "\u0CAE\u0C95", "\u0C95\u0CC1\u0C82", "\u0CAE\u0CC0"
        )

        fun update(context: Context, mgr: AppWidgetManager, id: Int) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

                // Sunrise: Flutter stores Double as Long (IEEE-754 bits)
                val sunrise: Double = if (prefs.contains(KEY_SR)) {
                    java.lang.Double.longBitsToDouble(
                        prefs.getLong(KEY_SR, java.lang.Double.doubleToLongBits(6.0))
                    )
                } else 6.0

                // Lagna rashi index 0-11, -1 = unknown
                val lagnaIdx: Int = if (prefs.contains(KEY_LG)) prefs.getInt(KEY_LG, -1) else -1

                val cal = Calendar.getInstance()
                val nowH = cal.get(Calendar.HOUR_OF_DAY) +
                           cal.get(Calendar.MINUTE) / 60.0 +
                           cal.get(Calendar.SECOND) / 3600.0
                val ghati = (nowH - sunrise) * 2.5   // 1 hour = 2.5 ghati

                val bmp = draw(ghati, lagnaIdx, SIZE)

                val views = RemoteViews(context.packageName, R.layout.ghati_widget_layout)
                views.setImageViewBitmap(R.id.ghati_clock_image, bmp)

                // Tap opens app
                context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { i ->
                    val pi = PendingIntent.getActivity(
                        context, 0, i,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.ghati_widget_root, pi)
                }

                mgr.updateAppWidget(id, views)
            } catch (e: Exception) {
                // Silently ignore — widget stays as-is until next tick
            }
        }

        // ── DRAWING ──────────────────────────────────────────────────────────

        private fun draw(ghati: Double, lagnaIdx: Int, size: Int): Bitmap {
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val c   = Canvas(bmp)
            val cx  = size / 2f
            val cy  = size / 2f
            val R   = cx - 6f

            // Background
            c.drawCircle(cx, cy, R, Paint().apply {
                shader = RadialGradient(
                    cx, cy, R,
                    intArrayOf(0xFF1A1A2E.toInt(), 0xFF16213E.toInt(), 0xFF0F3460.toInt()),
                    floatArrayOf(0f, 0.5f, 1f),
                    Shader.TileMode.CLAMP
                )
            })

            // Gold outer ring
            c.drawCircle(cx, cy, R, Paint().apply {
                color = 0xFFD4AF37.toInt()
                style = Paint.Style.STROKE
                strokeWidth = 3f
                isAntiAlias = true
            })

            // ── Rashi ring ──────────────────────────────
            val rOuter = R
            val rInner = R * 0.88f
            val rMid   = (rOuter + rInner) / 2f
            val ovalO  = RectF(cx - rOuter, cy - rOuter, cx + rOuter, cy + rOuter)
            val ovalI  = RectF(cx - rInner, cy - rInner, cx + rInner, cy + rInner)

            for (i in 0 until 12) {
                val startDeg = (i * 30f - 90f)
                val isLagna  = (i == lagnaIdx)
                val col      = RASHI_COL[i]
                val alpha    = if (isLagna) 0xBB else 0x44

                // Fill segment
                val seg = Path().apply {
                    val rad = Math.toRadians(startDeg.toDouble())
                    moveTo(cx + rInner * cos(rad).toFloat(), cy + rInner * sin(rad).toFloat())
                    arcTo(ovalO, startDeg, 30f)
                    arcTo(ovalI, startDeg + 30f, -30f)
                    close()
                }
                c.drawPath(seg, Paint().apply {
                    color = (alpha shl 24) or (col and 0x00FFFFFF)
                    style = Paint.Style.FILL
                    isAntiAlias = true
                })
                // Border
                c.drawPath(seg, Paint().apply {
                    color = if (isLagna) 0xFFFFD700.toInt()
                            else (0x88 shl 24) or (col and 0x00FFFFFF)
                    style = Paint.Style.STROKE
                    strokeWidth = if (isLagna) 2.8f else 0.6f
                    isAntiAlias = true
                })

                // Label
                val midRad = Math.toRadians((startDeg + 15.0))
                val lx = cx + rMid * cos(midRad).toFloat()
                val ly = cy + rMid * sin(midRad).toFloat()
                drawTxt(c, RASHI_LBL[i], lx, ly,
                    rOuter * (if (isLagna) 0.075f else 0.058f),
                    if (isLagna) 0xFFFFFFFF.toInt() else 0xCCFFFFFF.toInt(),
                    isLagna)

                // Gold arrow pointer for lagna
                if (isLagna) {
                    val ar = Math.toRadians((startDeg + 15.0))
                    val pr = rInner
                    val ps = R * 0.06f
                    val tri = Path().apply {
                        moveTo(cx + pr * cos(ar).toFloat(), cy + pr * sin(ar).toFloat())
                        lineTo(cx + (pr - ps) * cos(ar - 0.18).toFloat(),
                               cy + (pr - ps) * sin(ar - 0.18).toFloat())
                        lineTo(cx + (pr - ps) * cos(ar + 0.18).toFloat(),
                               cy + (pr - ps) * sin(ar + 0.18).toFloat())
                        close()
                    }
                    c.drawPath(tri, Paint().apply { color = 0xFFFFD700.toInt(); isAntiAlias = true })
                }
            }

            // Inner separator ring
            c.drawCircle(cx, cy, rInner, Paint().apply {
                color = 0x55D4AF37
                style = Paint.Style.STROKE
                strokeWidth = 1f
                isAntiAlias = true
            })

            // ── Ghati tick marks ─────────────────────────
            for (i in 0 until 60) {
                val a   = Math.toRadians(i * 6.0 - 90)
                val maj = (i % 5 == 0)
                val r1  = rInner * 0.99f
                val r2  = r1 - (if (maj) R * 0.07f else R * 0.025f)
                c.drawLine(
                    cx + r2 * cos(a).toFloat(), cy + r2 * sin(a).toFloat(),
                    cx + r1 * cos(a).toFloat(), cy + r1 * sin(a).toFloat(),
                    Paint().apply {
                        color = if (maj) 0xCCFFFFFF.toInt() else 0x44FFFFFF
                        strokeWidth = if (maj) 2f else 0.8f
                        isAntiAlias = true
                    }
                )
                if (maj) {
                    val nr = R * 0.70f
                    val lbl = if (i == 0) "\u0C89" else "$i"
                    drawTxt(c, lbl,
                        cx + nr * cos(a).toFloat(), cy + nr * sin(a).toFloat(),
                        R * (if (i == 0) 0.06f else 0.048f),
                        if (i == 0) 0xFFFFD700.toInt() else 0xAAFFFFFF.toInt(),
                        i == 0)
                }
            }

            // Inner circle
            c.drawCircle(cx, cy, R * 0.60f, Paint().apply {
                color = 0x22D4AF37
                style = Paint.Style.STROKE
                strokeWidth = 0.8f
                isAntiAlias = true
            })

            // ── Digital text inside clock ────────────────
            val gh    = (ghati.toInt() % 60).coerceIn(0, 59)
            val viTot = (ghati - ghati.toInt()) * 60
            val vi    = viTot.toInt().coerceIn(0, 59)
            val av    = ((viTot - vi) * 60).toInt().coerceIn(0, 59)
            val ghKn  = "\u0C98"   // ಘ
            val viKn  = "\u0CB5\u0CBF"  // ವಿ
            val avKn  = "\u0C85"   // ಅ
            val txt   = "$gh $ghKn : ${vi.toString().padStart(2,'0')} $viKn : ${av.toString().padStart(2,'0')} $avKn"
            drawTxt(c, txt, cx, cy, R * 0.085f, 0xFFFFFFFF.toInt(), true)

            // ── Hands ────────────────────────────────────
            val vighatiTot = (ghati - ghati.toInt()) * 60
            val anuVighati = (vighatiTot - vighatiTot.toInt()) * 60
            val aGh  = ((ghati % 60) * 6.0 - 90).toFloat()
            val aVi  = (vighatiTot * 6.0 - 90).toFloat()
            val aAnu = (anuVighati * 6.0 - 90).toFloat()

            hand(c, cx, cy, aGh,  R * 0.42f, 5.5f, 0xFFE53E3E.toInt(), R * 0.09f)
            hand(c, cx, cy, aVi,  R * 0.56f, 3.5f, 0xFF2B6CB0.toInt(), R * 0.07f)
            hand(c, cx, cy, aAnu, R * 0.72f, 1.8f, 0xFF38A169.toInt(), R * 0.05f)

            // Centre hub
            c.drawCircle(cx, cy, 14f, Paint().apply {
                shader = RadialGradient(cx, cy, 14f,
                    intArrayOf(0xFFD4AF37.toInt(), 0xFF8B6914.toInt()), null,
                    Shader.TileMode.CLAMP)
                isAntiAlias = true
            })
            c.drawCircle(cx, cy, 14f, Paint().apply {
                color = 0x55FFFFFF; style = Paint.Style.STROKE; strokeWidth = 1.5f; isAntiAlias = true
            })
            c.drawCircle(cx, cy, 5f, Paint().apply {
                color = 0xFF1A1A2E.toInt(); isAntiAlias = true
            })

            return bmp
        }

        private fun hand(c: Canvas, cx: Float, cy: Float, deg: Float,
                         len: Float, w: Float, col: Int, tail: Float) {
            val a  = Math.toRadians(deg.toDouble())
            val tx = cx + len  * cos(a).toFloat();  val ty = cy + len  * sin(a).toFloat()
            val bx = cx - tail * cos(a).toFloat();  val by = cy - tail * sin(a).toFloat()
            // Glow
            c.drawLine(bx, by, tx, ty, Paint().apply {
                color = (col and 0x00FFFFFF) or 0x33000000
                strokeWidth = w + 6; strokeCap = Paint.Cap.ROUND; isAntiAlias = true
            })
            // Shaft
            c.drawLine(bx, by, tx, ty, Paint().apply {
                color = col; strokeWidth = w; strokeCap = Paint.Cap.ROUND; isAntiAlias = true
            })
            // Arrowhead
            val aw = w * 3f; val al = w * 5f
            val b1x = tx - al * cos(a).toFloat() + aw / 2 * cos(a + PI / 2).toFloat()
            val b1y = ty - al * sin(a).toFloat() + aw / 2 * sin(a + PI / 2).toFloat()
            val b2x = tx - al * cos(a).toFloat() - aw / 2 * cos(a + PI / 2).toFloat()
            val b2y = ty - al * sin(a).toFloat() - aw / 2 * sin(a + PI / 2).toFloat()
            c.drawPath(Path().apply { moveTo(tx, ty); lineTo(b1x, b1y); lineTo(b2x, b2y); close() },
                Paint().apply { color = col; isAntiAlias = true })
        }

        private fun drawTxt(c: Canvas, t: String, x: Float, y: Float,
                            fs: Float, col: Int, bold: Boolean) {
            val p = Paint().apply {
                color = col; textSize = fs; textAlign = Paint.Align.CENTER; isAntiAlias = true
                if (bold) typeface = Typeface.DEFAULT_BOLD
            }
            val fm = p.fontMetrics
            c.drawText(t, x, y - (fm.ascent + fm.descent) / 2f, p)
        }

        // ── Alarm ─────────────────────────────────────────────────────────────

        private fun alarmIntent(context: Context): PendingIntent {
            val i = Intent(ACTION_TICK, null, context, GhatiWidgetProvider::class.java)
            return PendingIntent.getBroadcast(
                context, 42, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun scheduleAlarm(context: Context) {
            val am  = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi  = alarmIntent(context)
            val due = SystemClock.elapsedRealtime() + 60_000L
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi)
                else
                    am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi)
            } catch (_: SecurityException) {
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi)
            }
        }

        fun cancelAlarm(context: Context) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
                .cancel(alarmIntent(context))
        }
    }
}
