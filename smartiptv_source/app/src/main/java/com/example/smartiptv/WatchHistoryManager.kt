package com.example.smartiptv

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object WatchHistoryManager {
    private const val PREF_NAME = "IPTV_Watch_Prefs"
    private const val FAV_KEY = "favorite_ids"
    private const val RECENT_KEY = "recent_history"

    fun getFavorites(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(FAV_KEY, emptySet()) ?: emptySet()
    }

    fun isFavorite(context: Context, streamId: String): Boolean {
        return getFavorites(context).contains(streamId)
    }

    fun toggleFavorite(context: Context, streamId: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val currentFavs = prefs.getStringSet(FAV_KEY, emptySet())?.toMutableSet() ?: mutableSetOf()

        if (currentFavs.contains(streamId)) currentFavs.remove(streamId)
        else currentFavs.add(streamId)

        prefs.edit().putStringSet(FAV_KEY, currentFavs).apply()
    }

    // حفظ التقدم والاستئناف
    fun saveProgress(context: Context, streamId: String, position: Long, duration: Long) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        if (position > 3000 && duration > 0 && (duration - position > 5000)) {
            prefs.edit().putLong("progress_$streamId", position).apply()
        } else {
            prefs.edit().remove("progress_$streamId").apply()
        }
    }

    fun getProgress(context: Context, streamId: String): Long {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getLong("progress_$streamId", 0L)
    }

    // إدارة السجل (Recent)
    fun addToRecent(context: Context, item: StreamItem) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val historyJson = prefs.getString(RECENT_KEY, "[]")
        val array = JSONArray(historyJson)
        
        // منع التكرار: حذف العنصر إذا كان موجوداً مسبقاً لإعادة وضعه في البداية
        val newList = mutableListOf<JSONObject>()
        val newItem = JSONObject().apply {
            put("id", item.streamId)
            put("name", item.name)
            put("icon", item.streamIcon)
            put("type", item.streamType)
        }
        newList.add(newItem)

        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            if (obj.getString("id") != item.streamId && newList.size < 20) {
                newList.add(obj)
            }
        }
        
        val newArray = JSONArray()
        newList.forEach { newArray.put(it) }
        prefs.edit().putString(RECENT_KEY, newArray.toString()).apply()
    }

    fun getRecent(context: Context): List<StreamItem> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val historyJson = prefs.getString(RECENT_KEY, "[]")
        val array = JSONArray(historyJson)
        val list = mutableListOf<StreamItem>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            list.add(StreamItem(
                obj.getString("id"),
                obj.getString("name"),
                obj.getString("icon"),
                obj.getString("type")
            ))
        }
        return list
    }
}