package dev.artiz.az_budget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen widget: the calendar month's expenses against the limit, with
 * the traffic-light colour. The Dart side pushes the numbers after every
 * sync (method channel `dev.artiz.az_budget/widget`); they are kept in
 * shared preferences so the launcher can redraw without the app running.
 */
class MonthWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) appWidgetManager.updateAppWidget(id, build(context))
    }

    companion object {
        const val PREFS = "az_widget"

        fun store(context: Context, title: String, amount: String, color: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("amount", amount)
                .putInt("color", color)
                .apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, MonthWidget::class.java))
            if (ids.isEmpty()) return
            val views = build(context)
            for (id in ids) manager.updateAppWidget(id, views)
        }

        private fun build(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_month)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "AZ Budget"))
            views.setTextViewText(R.id.widget_amount, prefs.getString("amount", context.getString(R.string.widget_empty)))
            views.setInt(R.id.widget_dot, "setColorFilter", prefs.getInt("color", 0xFF3BA55D.toInt()))
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val open = Intent(context, MainActivity::class.java).setAction(Intent.ACTION_MAIN)
            views.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, 1, open, flags))
            val add = Intent(context, MainActivity::class.java).setAction("dev.artiz.az_budget.NEW_ENTRY")
            views.setOnClickPendingIntent(R.id.widget_add, PendingIntent.getActivity(context, 2, add, flags))
            return views
        }
    }
}
