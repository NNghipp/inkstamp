package com.inkstamp.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

class InkstampWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, InkstampWidgetReceiver::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            for (widgetId in widgetIds) {
                updateWidget(context, manager, widgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val preferences = context.getSharedPreferences(
                "inkstamp_widget",
                Context.MODE_PRIVATE,
            )
            val stampId = preferences.getString("latest_stamp_id", null)
            val sender = preferences.getString("latest_sender", "Inkstamp") ?: "Inkstamp"
            val thumbnailPath = preferences.getString("latest_thumbnail_path", null)
            val thumbnail = thumbnailPath?.let(BitmapFactory::decodeFile)
            val views = RemoteViews(context.packageName, R.layout.inkstamp_widget)

            views.setTextViewText(R.id.inkstamp_widget_sender, sender)
            if (thumbnail != null) {
                views.setImageViewBitmap(R.id.inkstamp_widget_image, thumbnail)
                views.setViewVisibility(R.id.inkstamp_widget_image, View.VISIBLE)
                views.setViewVisibility(R.id.inkstamp_widget_placeholder, View.GONE)
            } else {
                views.setViewVisibility(R.id.inkstamp_widget_image, View.GONE)
                views.setViewVisibility(R.id.inkstamp_widget_placeholder, View.VISIBLE)
            }

            val deepLink = if (stampId == null) {
                "inkstamp://camera"
            } else {
                "inkstamp://stamp/$stampId"
            }
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                setPackage(context.packageName)
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.inkstamp_widget_root, pendingIntent)
            manager.updateAppWidget(widgetId, views)
        }
    }
}
