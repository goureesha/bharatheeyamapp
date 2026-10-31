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

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) update(context, mgr, id)
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
        private const val PREFS  = "FlutterSharedPreferences"
        private const val KEY_SR = "flutter.sunrise_hour24"
        private const val KEY_LG = "flutter.lagna_rashi_index"

        // 200×200 ARGB_8888 = 160 KB — well within any device's Binder IPC limit
        private const val SIZE = 200

        private val RASHI_COL = intArrayOf(
            0xFFE74C3C.toInt(), 0xFF27AE60.toInt(), 0xFF3498DB.toInt(), 0xFF8E44AD.toInt(),
            0xFFE67E22.toInt(), 0xFF2ECC71.toInt(), 0xFF2980B9.toInt(), 0xFF9B59B6.toInt(),
            0xFFD35400.toInt(), 0xFF1ABC9C.toInt(), 0xFF2471A3.toInt(), 0xFF7D3C98.toInt()
        )
        private val RASHI_LBL = arrayOf(
            "\u0CAE\u0CC7", "\u0CB5\u0CC3", "\u0CAE\u0CBF", "\u0C95",
            "\u0CB8\u0CBF", "\u0C95\u0CA8\u0CCD", "\u0CA4\u0CC1", "\u0CB5\u0CC3\u0C9A\u0CCD",
            "\u0CA7", "\u0CAE\u0C95", "\u0C95\u0CC1\u0C82", "\u0CAE\u0CC0"
        )

        fun update(context: Context, mgr: AppWidgetManager, id: Int) {
            val views = RemoteViews(context.packageName, R.layout.ghati_widget_layout)

            // Always set click handler first — works even if drawing fails
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
                val pi = PendingIntent.getActivity(
                    context, 0, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.ghati_widget_root, pi)
            }

            // Read prefs
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val sunrise: Double = try {
                if (prefs.contains(KEY_SR))
                    java.lang.Double.longBitsToDouble(prefs.getLong(KEY_SR, java.lang.Double.doubleToLongBits(6.0)))
                else 6.0
            } catch (_: Exception) { 6.0 }

            val lagnaIdx: Int = try {
                if (prefs.contains(KEY_LG)) prefs.getInt(KEY_LG, -1) else -1
            } catch (_: Exception) { -1 }

            // Current ghati
            val cal   = Calendar.getInstance()
            val nowH  = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE) / 60.0 + cal.get(Calendar.SECOND) / 3600.0
            val ghati = (nowH - sunrise) * 2.5

            // Draw — if anything throws, draw a minimal error bitmap instead of blank
            val bmp = try {
                drawClock(ghati, lagnaIdx)
            } catch (e: Exception) {
                drawError()
            }

            views.setImageViewBitmap(R.id.ghati_clock_image, bmp)
            mgr.updateAppWidget(id, views)
        }

        // ── CLOCK ────────────────────────────────────────────────────────────

        private fun drawClock(ghati: Double, lagnaIdx: Int): Bitmap {
            val sz = SIZE
            val bmp = Bitmap.createBitmap(sz, sz, Bitmap.Config.ARGB_8888)
            val cv  = Canvas(bmp)
            val cx  = sz / 2f;  val cy = sz / 2f
            val R   = cx - 4f

            // Background circle
            cv.drawCircle(cx, cy, R, Paint().apply {
                shader = RadialGradient(cx, cy, R,
                    intArrayOf(0xFF1A1A2E.toInt(), 0xFF0F3460.toInt()),
                    floatArrayOf(0f, 1f), Shader.TileMode.CLAMP)
            })

            // Gold outer border
            cv.drawCircle(cx, cy, R, Paint().apply {
                color = 0xFFD4AF37.toInt(); style = Paint.Style.STROKE; strokeWidth = 2f; isAntiAlias = true
            })

            // Rashi ring
            val rO = R;  val rI = R * 0.87f;  val rM = (rO + rI) / 2f
            val oO = RectF(cx-rO, cy-rO, cx+rO, cy+rO)
            val oI = RectF(cx-rI, cy-rI, cx+rI, cy+rI)

            for (i in 0 until 12) {
                val sd  = i * 30f - 90f
                val col = RASHI_COL[i]
                val isL = (i == lagnaIdx)
                val seg = Path().apply {
                    val r = Math.toRadians(sd.toDouble())
                    moveTo(cx + rI*cos(r).toFloat(), cy + rI*sin(r).toFloat())
                    arcTo(oO, sd, 30f)
                    arcTo(oI, sd+30f, -30f)
                    close()
                }
                cv.drawPath(seg, Paint().apply {
                    color = ((if (isL) 0xBB else 0x44) shl 24) or (col and 0x00FFFFFF)
                    style = Paint.Style.FILL; isAntiAlias = true
                })
                cv.drawPath(seg, Paint().apply {
                    color = if (isL) 0xFFFFD700.toInt() else (0x77 shl 24) or (col and 0x00FFFFFF)
                    style = Paint.Style.STROKE; strokeWidth = if (isL) 2f else 0.5f; isAntiAlias = true
                })
                // Label
                val ma = Math.toRadians((sd + 15.0))
                txt(cv, RASHI_LBL[i], cx+rM*cos(ma).toFloat(), cy+rM*sin(ma).toFloat(),
                    rO*(if(isL) 0.072f else 0.054f),
                    if(isL) 0xFFFFFFFF.toInt() else 0xCCFFFFFF.toInt(), isL)
                // Lagna arrow
                if (isL) {
                    val pa = Math.toRadians((sd+15.0));  val ps = R*0.06f
                    cv.drawPath(Path().apply {
                        moveTo(cx+rI*cos(pa).toFloat(), cy+rI*sin(pa).toFloat())
                        lineTo(cx+(rI-ps)*cos(pa-0.2).toFloat(), cy+(rI-ps)*sin(pa-0.2).toFloat())
                        lineTo(cx+(rI-ps)*cos(pa+0.2).toFloat(), cy+(rI-ps)*sin(pa+0.2).toFloat())
                        close()
                    }, Paint().apply { color = 0xFFFFD700.toInt(); isAntiAlias = true })
                }
            }

            // Rashi inner ring
            cv.drawCircle(cx, cy, rI, Paint().apply {
                color = 0x55D4AF37; style = Paint.Style.STROKE; strokeWidth = 0.8f; isAntiAlias = true
            })

            // Ghati tick marks
            for (i in 0 until 60) {
                val a = Math.toRadians(i*6.0-90); val maj = i%5==0
                val r1=rI*0.99f; val r2=r1-(if(maj) R*0.07f else R*0.025f)
                cv.drawLine(cx+r2*cos(a).toFloat(), cy+r2*sin(a).toFloat(),
                    cx+r1*cos(a).toFloat(), cy+r1*sin(a).toFloat(),
                    Paint().apply {
                        color=if(maj)0xCCFFFFFF.toInt() else 0x44FFFFFF
                        strokeWidth=if(maj)1.5f else 0.6f; isAntiAlias=true
                    })
                if (maj) {
                    val nr=R*0.70f; val lbl=if(i==0)"\u0C89" else "$i"
                    txt(cv, lbl, cx+nr*cos(a).toFloat(), cy+nr*sin(a).toFloat(),
                        R*(if(i==0)0.055f else 0.042f),
                        if(i==0)0xFFFFD700.toInt() else 0xAAFFFFFF.toInt(), i==0)
                }
            }

            // Inner ring
            cv.drawCircle(cx, cy, R*0.60f, Paint().apply {
                color=0x22D4AF37; style=Paint.Style.STROKE; strokeWidth=0.6f; isAntiAlias=true
            })

            // Digital ghati text in centre
            val gh=(ghati.toInt()%60).coerceIn(0,59)
            val vt=(ghati-ghati.toInt())*60; val vi=vt.toInt().coerceIn(0,59)
            val av=((vt-vi)*60).toInt().coerceIn(0,59)
            txt(cv, "$gh \u0C98:${vi.toString().padStart(2,'0')} \u0CB5\u0CBF:${av.toString().padStart(2,'0')} \u0C85",
                cx, cy, R*0.080f, 0xFFFFFFFF.toInt(), true)

            // Hands
            val vt2=(ghati-ghati.toInt())*60; val av2=(vt2-vt2.toInt())*60
            hand(cv,cx,cy, ((ghati%60)*6-90).toFloat(), R*0.42f, 4.5f, 0xFFE53E3E.toInt(), R*0.09f)
            hand(cv,cx,cy, (vt2*6-90).toFloat(),        R*0.56f, 2.8f, 0xFF2B6CB0.toInt(), R*0.07f)
            hand(cv,cx,cy, (av2*6-90).toFloat(),        R*0.72f, 1.5f, 0xFF38A169.toInt(), R*0.05f)

            // Hub
            cv.drawCircle(cx,cy,10f, Paint().apply {
                shader=RadialGradient(cx,cy,10f, intArrayOf(0xFFD4AF37.toInt(),0xFF8B6914.toInt()),null,Shader.TileMode.CLAMP); isAntiAlias=true
            })
            cv.drawCircle(cx,cy,4f, Paint().apply { color=0xFF1A1A2E.toInt(); isAntiAlias=true })

            return bmp
        }

        // Minimal fallback bitmap — dark circle with error text so widget is never blank
        private fun drawError(): Bitmap {
            val bmp = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
            val cv  = Canvas(bmp)
            val cx  = SIZE/2f;  val cy = SIZE/2f;  val R = cx-4f
            cv.drawCircle(cx, cy, R, Paint().apply { color = 0xFF1A1A2E.toInt() })
            cv.drawCircle(cx, cy, R, Paint().apply { color=0xFFD4AF37.toInt(); style=Paint.Style.STROKE; strokeWidth=2f })
            txt(cv, "\u0CAD\u0CBE\u0CB0\u0CA4\u0CC0\u0CAF\u0CAE\u0CCD", cx, cy, R*0.13f, 0xFFFFD700.toInt(), true)
            return bmp
        }

        private fun hand(cv: Canvas, cx: Float, cy: Float, deg: Float,
                         len: Float, w: Float, col: Int, tail: Float) {
            val a = Math.toRadians(deg.toDouble())
            val tx=cx+len*cos(a).toFloat(); val ty=cy+len*sin(a).toFloat()
            val bx=cx-tail*cos(a).toFloat(); val by=cy-tail*sin(a).toFloat()
            cv.drawLine(bx,by,tx,ty, Paint().apply {
                color=(col and 0x00FFFFFF) or 0x33000000; strokeWidth=w+5; strokeCap=Paint.Cap.ROUND; isAntiAlias=true
            })
            cv.drawLine(bx,by,tx,ty, Paint().apply {
                color=col; strokeWidth=w; strokeCap=Paint.Cap.ROUND; isAntiAlias=true
            })
            val aw=w*3f; val al=w*5f
            cv.drawPath(Path().apply {
                moveTo(tx,ty)
                lineTo(tx-al*cos(a).toFloat()+aw/2*cos(a+PI/2).toFloat(), ty-al*sin(a).toFloat()+aw/2*sin(a+PI/2).toFloat())
                lineTo(tx-al*cos(a).toFloat()-aw/2*cos(a+PI/2).toFloat(), ty-al*sin(a).toFloat()-aw/2*sin(a+PI/2).toFloat())
                close()
            }, Paint().apply { color=col; isAntiAlias=true })
        }

        private fun txt(cv: Canvas, t: String, x: Float, y: Float, fs: Float, col: Int, bold: Boolean) {
            val p = Paint().apply {
                color=col; textSize=fs; textAlign=Paint.Align.CENTER; isAntiAlias=true
                if (bold) typeface=Typeface.DEFAULT_BOLD
            }
            val fm = p.fontMetrics
            cv.drawText(t, x, y-(fm.ascent+fm.descent)/2f, p)
        }

        // ── Alarm ────────────────────────────────────────────────────────────

        private fun pi(context: Context) = PendingIntent.getBroadcast(
            context, 42,
            Intent(ACTION_TICK, null, context, GhatiWidgetProvider::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        fun scheduleAlarm(context: Context) {
            val am  = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val due = SystemClock.elapsedRealtime() + 60_000L
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi(context))
                else
                    am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi(context))
            } catch (_: SecurityException) {
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, due, pi(context))
            }
        }

        fun cancelAlarm(context: Context) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi(context))
        }
    }
}
