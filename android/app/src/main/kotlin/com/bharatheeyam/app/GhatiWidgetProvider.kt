package com.bharatheeyam.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.widget.RemoteViews
import java.util.Calendar
import kotlin.math.*

class GhatiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
        GhatiWidgetUpdateService.scheduleNextUpdate(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        GhatiWidgetUpdateService.scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        GhatiWidgetUpdateService.cancelUpdates(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.bharatheeyam.CLOCK_UPDATE" ||
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                android.content.ComponentName(context, GhatiWidgetProvider::class.java)
            )
            onUpdate(context, mgr, ids)
        }
    }

    companion object {
        private const val WIDGET_SIZE = 240

        // 12 rashi colours matching the Dart app
        private val RASHI_COLORS = intArrayOf(
            0xFFE74C3C.toInt(), 0xFF27AE60.toInt(), 0xFF3498DB.toInt(), 0xFF8E44AD.toInt(),
            0xFFE67E22.toInt(), 0xFF2ECC71.toInt(), 0xFF2980B9.toInt(), 0xFF9B59B6.toInt(),
            0xFFD35400.toInt(), 0xFF1ABC9C.toInt(), 0xFF2471A3.toInt(), 0xFF7D3C98.toInt()
        )

        // Rashi short labels (Kannada)
        private val RASHI_LABELS = arrayOf(
            "\u0CAE\u0CC7", "\u0CB5\u0CC3", "\u0CAE\u0CBF", "\u0C95\u0CB0",
            "\u0CB8\u0CBF", "\u0C95\u0CA8\u0CCD","\u0CA4\u0CC1", "\u0CB5\u0CC3\u0C9A\u0CCD",
            "\u0CA7", "\u0CAE\u0C95", "\u0C95\u0CC1\u0C82", "\u0CAE\u0CC0"
        )

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.ghati_widget_layout)

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // Read sunrise (stored as IEEE-754 long bits by Flutter)
            val sunriseHour: Double = if (prefs.contains("flutter.sunrise_hour24")) {
                val bits = prefs.getLong("flutter.sunrise_hour24", java.lang.Double.doubleToLongBits(6.0))
                java.lang.Double.longBitsToDouble(bits)
            } else { 6.0 }

            // Read current lagna rashi index (0–11), stored as Int by Flutter
            val lagnaRashiIdx: Int = if (prefs.contains("flutter.lagna_rashi_index")) {
                prefs.getInt("flutter.lagna_rashi_index", 0)
            } else { -1 }  // -1 = unknown, skip highlight

            try {
                val cal = Calendar.getInstance()
                val nowHour = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE) / 60.0 + cal.get(Calendar.SECOND) / 3600.0
                val ghati = (nowHour - sunriseHour) * (60.0 / 24.0)

                val bitmap = drawClock(ghati, WIDGET_SIZE, lagnaRashiIdx)
                views.setImageViewBitmap(R.id.ghati_clock_image, bitmap)

                val gh = ghati.toInt() % 60
                val viTotal = (ghati - ghati.toInt()) * 60
                val vi = viTotal.toInt()
                val av = ((viTotal - vi) * 60).toInt()
                views.setTextViewText(R.id.ghati_text, "${gh} ಘ : ${vi.toString().padStart(2,'0')} ವಿ : ${av.toString().padStart(2,'0')} ಅ")

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = android.app.PendingIntent.getActivity(
                        context, 0, launchIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.ghati_widget_root, pendingIntent)
                }
            } catch (e: Exception) {
                try {
                    val cal2 = Calendar.getInstance()
                    val nowH2 = cal2.get(Calendar.HOUR_OF_DAY) + cal2.get(Calendar.MINUTE) / 60.0 + cal2.get(Calendar.SECOND) / 3600.0
                    val ghati2 = (nowH2 - sunriseHour) * (60.0 / 24.0)
                    val fallbackBitmap = drawClock(ghati2, WIDGET_SIZE, lagnaRashiIdx)
                    views.setImageViewBitmap(R.id.ghati_clock_image, fallbackBitmap)
                    val gh2 = ghati2.toInt() % 60
                    val viT2 = (ghati2 - ghati2.toInt()) * 60
                    val vi2 = viT2.toInt()
                    val av2 = ((viT2 - vi2) * 60).toInt()
                    views.setTextViewText(R.id.ghati_text, "${gh2} ಘ : ${vi2.toString().padStart(2,'0')} ವಿ : ${av2.toString().padStart(2,'0')} ಅ")
                } catch (_: Exception) {
                    views.setTextViewText(R.id.ghati_text, "\u0CAD\u0CBE\u0CB0\u0CA4\u0CC0\u0CAF\u0CAE\u0CCD")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun drawClock(ghati: Double, size: Int, lagnaRashiIdx: Int): Bitmap {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val cx = size / 2f
            val cy = size / 2f
            val R = cx - 8f

            val vighatiTotal = (ghati - ghati.toInt()) * 60
            val vighatiWhole = vighatiTotal.toInt()
            val anuVighati = (vighatiTotal - vighatiWhole) * 60

            val ghatiAngle   = ((ghati % 60) * 6.0 - 90).toFloat()
            val vighatiAngle = (vighatiTotal * 6.0 - 90).toFloat()
            val anuAngle     = (anuVighati * 6.0 - 90).toFloat()

            // --- Background ---
            val bgPaint = Paint().apply {
                shader = RadialGradient(cx, cy, R,
                    intArrayOf(0xFF1A1A2E.toInt(), 0xFF16213E.toInt(), 0xFF0F3460.toInt()),
                    floatArrayOf(0f, 0.5f, 1f), Shader.TileMode.CLAMP)
            }
            canvas.drawCircle(cx, cy, R, bgPaint)
            // Outer gold ring
            canvas.drawCircle(cx, cy, R, Paint().apply {
                color = 0xFFD4AF37.toInt(); style = Paint.Style.STROKE; strokeWidth = 3f; isAntiAlias = true
            })

            // --- Rashi ring ---
            val outerR   = R
            val innerRashi = R * 0.92f

            for (i in 0 until 12) {
                val startDeg = (i * 30.0 - 90.0).toFloat()
                val isLagna  = (i == lagnaRashiIdx)
                val baseColor = RASHI_COLORS[i]

                // Segment fill
                val fillPaint = Paint().apply {
                    color = (baseColor and 0x00FFFFFF) or (if (isLagna) 0xA6000000.toInt() else 0x33000000.toInt())
                    style = Paint.Style.FILL
                    isAntiAlias = true
                }
                val oval = RectF(cx - outerR, cy - outerR, cx + outerR, cy + outerR)
                val innerOval = RectF(cx - innerRashi, cy - innerRashi, cx + innerRashi, cy + innerRashi)
                val path = Path().apply {
                    val sa = Math.toRadians(startDeg.toDouble())
                    val ea = Math.toRadians((startDeg + 30f).toDouble())
                    moveTo((cx + innerRashi * cos(sa)).toFloat(), (cy + innerRashi * sin(sa)).toFloat())
                    arcTo(oval, startDeg, 30f)
                    arcTo(innerOval, startDeg + 30f, -30f)
                    close()
                }
                canvas.drawPath(path, fillPaint)

                // Segment border
                val borderPaint = Paint().apply {
                    color = if (isLagna) 0xFFFFD700.toInt() else (baseColor and 0x00FFFFFF) or 0x66000000.toInt()
                    style = Paint.Style.STROKE
                    strokeWidth = if (isLagna) 2.5f else 0.8f
                    isAntiAlias = true
                }
                canvas.drawPath(path, borderPaint)

                // Rashi label in mid-arc
                val midA = Math.toRadians((startDeg + 15.0))
                val midR  = (outerR + innerRashi) / 2f
                val lx = (cx + midR * cos(midA)).toFloat()
                val ly = (cy + midR * sin(midA)).toFloat()
                drawText(canvas, RASHI_LABELS[i], lx, ly,
                    outerR * (if (isLagna) 0.060f else 0.048f),
                    if (isLagna) 0xFFFFFFFF.toInt() else 0xB3FFFFFF.toInt(), isLagna)

                // Gold lagna pointer triangle on inner edge
                if (isLagna) {
                    val pa = Math.toRadians((startDeg + 15.0))
                    val pr = innerRashi - 1f
                    val ps = R * 0.04f
                    val pPath = Path().apply {
                        moveTo((cx + pr * cos(pa)).toFloat(), (cy + pr * sin(pa)).toFloat())
                        lineTo((cx + (pr + ps) * cos(pa - 0.12)).toFloat(), (cy + (pr + ps) * sin(pa - 0.12)).toFloat())
                        lineTo((cx + (pr + ps) * cos(pa + 0.12)).toFloat(), (cy + (pr + ps) * sin(pa + 0.12)).toFloat())
                        close()
                    }
                    canvas.drawPath(pPath, Paint().apply { color = 0xFFFFD700.toInt(); isAntiAlias = true })
                    canvas.drawPath(pPath, Paint().apply { color = 0xFFFFFFFF.toInt(); style = Paint.Style.STROKE; strokeWidth = 0.8f; isAntiAlias = true })
                }
            }

            // Inner separator ring
            canvas.drawCircle(cx, cy, innerRashi, Paint().apply {
                color = 0x30D4AF37; style = Paint.Style.STROKE; strokeWidth = 1f; isAntiAlias = true
            })

            // --- Ghati markers 0–59 ---
            for (i in 0 until 60) {
                val a = Math.toRadians((i * 6.0 - 90))
                val isMajor = i % 5 == 0
                val len = if (isMajor) R * 0.08f else R * 0.03f
                val w   = if (isMajor) 2.5f else 0.8f
                val r1  = innerRashi * 0.995f
                val r2  = r1 - len
                val c   = if (isMajor) 0xCCFFFFFF.toInt() else 0x33FFFFFF
                canvas.drawLine(
                    (cx + r2 * cos(a)).toFloat(), (cy + r2 * sin(a)).toFloat(),
                    (cx + r1 * cos(a)).toFloat(), (cy + r1 * sin(a)).toFloat(),
                    Paint().apply { color = c; strokeWidth = w; isAntiAlias = true })

                if (isMajor) {
                    val numR = R * 0.72f
                    val label = if (i == 0) "\u0C89" else "$i"
                    val fs = if (i == 0) R * 0.056f else R * 0.046f
                    val tc = if (i == 0) 0xFFFFD700.toInt() else 0xB3FFFFFF.toInt()
                    drawText(canvas, label, (cx + numR * cos(a)).toFloat(), (cy + numR * sin(a)).toFloat(), fs, tc, i == 0)
                }
            }

            // Inner ring
            canvas.drawCircle(cx, cy, R * 0.62f, Paint().apply {
                color = 0x20D4AF37; style = Paint.Style.STROKE; strokeWidth = 1f; isAntiAlias = true
            })

            // --- Hands ---
            drawHand(canvas, cx, cy, ghatiAngle,   R * 0.45f, 5f, 0xFFE53E3E.toInt(), R * 0.08f)
            drawHand(canvas, cx, cy, vighatiAngle, R * 0.60f, 3f, 0xFF2B6CB0.toInt(), R * 0.06f)
            drawHand(canvas, cx, cy, anuAngle,     R * 0.75f, 1.5f, 0xFF38A169.toInt(), R * 0.04f)

            // Center hub
            canvas.drawCircle(cx, cy, 14f, Paint().apply {
                shader = RadialGradient(cx, cy, 14f, intArrayOf(0xFFD4AF37.toInt(), 0xFF8B6914.toInt()), null, Shader.TileMode.CLAMP)
                isAntiAlias = true
            })
            canvas.drawCircle(cx, cy, 14f, Paint().apply { color = 0x4DFFFFFF; style = Paint.Style.STROKE; strokeWidth = 1.5f; isAntiAlias = true })
            canvas.drawCircle(cx, cy,  5f, Paint().apply { color = 0xFF1A1A2E.toInt(); isAntiAlias = true })

            return bitmap
        }

        private fun drawHand(canvas: Canvas, cx: Float, cy: Float, angleDeg: Float, length: Float, width: Float, color: Int, tailLen: Float) {
            val a = Math.toRadians(angleDeg.toDouble())
            val tipX  = cx + length * cos(a).toFloat()
            val tipY  = cy + length * sin(a).toFloat()
            val tailX = cx - tailLen * cos(a).toFloat()
            val tailY = cy - tailLen * sin(a).toFloat()
            // Glow
            canvas.drawLine(tailX, tailY, tipX, tipY, Paint().apply {
                this.color = (color and 0x00FFFFFF) or 0x33000000; strokeWidth = width + 5; strokeCap = Paint.Cap.ROUND; isAntiAlias = true
            })
            // Shaft
            canvas.drawLine(tailX, tailY, tipX, tipY, Paint().apply {
                this.color = color; strokeWidth = width; strokeCap = Paint.Cap.ROUND; isAntiAlias = true
            })
            // Arrowhead
            val aW = width * 2.5f; val aL = width * 4f
            val b1x = tipX - aL * cos(a).toFloat() + aW / 2 * cos(a + Math.PI / 2).toFloat()
            val b1y = tipY - aL * sin(a).toFloat() + aW / 2 * sin(a + Math.PI / 2).toFloat()
            val b2x = tipX - aL * cos(a).toFloat() - aW / 2 * cos(a + Math.PI / 2).toFloat()
            val b2y = tipY - aL * sin(a).toFloat() - aW / 2 * sin(a + Math.PI / 2).toFloat()
            canvas.drawPath(Path().apply { moveTo(tipX, tipY); lineTo(b1x, b1y); lineTo(b2x, b2y); close() },
                Paint().apply { this.color = color; isAntiAlias = true })
        }

        private fun drawText(canvas: Canvas, text: String, x: Float, y: Float, fontSize: Float, color: Int, bold: Boolean) {
            val paint = Paint().apply {
                this.color = color; textSize = fontSize; textAlign = Paint.Align.CENTER; isAntiAlias = true
                if (bold) typeface = Typeface.DEFAULT_BOLD
            }
            val fm = paint.fontMetrics
            canvas.drawText(text, x, y - (fm.ascent + fm.descent) / 2, paint)
        }
    }
}
