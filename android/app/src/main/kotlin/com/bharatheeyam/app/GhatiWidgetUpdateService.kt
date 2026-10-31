package com.bharatheeyam.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

class GhatiWidgetUpdateService : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(
            ComponentName(context, GhatiWidgetProvider::class.java)
        )
        for (id in ids) {
            GhatiWidgetProvider.updateWidget(context, mgr, id)
        }

        // Schedule next update in 60 seconds
        scheduleNextUpdate(context)
    }

    companion object {
        private const val ACTION_UPDATE = "com.bharatheeyam.GHATI_TICK"

        fun scheduleNextUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(ACTION_UPDATE).apply {
                setClass(context, GhatiWidgetUpdateService::class.java)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val triggerAt = SystemClock.elapsedRealtime() + 60_000L

            // Use exact wakeup alarm so the widget ticks even when screen is off
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent
                    )
                }
            } catch (e: SecurityException) {
                // On Android 12+ exact alarms need SCHEDULE_EXACT_ALARM permission.
                // Fall back to inexact wakeup — widget will still update but timing is loose.
                alarmManager.set(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent
                )
            }
        }

        fun cancelUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(ACTION_UPDATE).apply {
                setClass(context, GhatiWidgetUpdateService::class.java)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}
