package com.example.smartiptv

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray

class StreamsViewModel : ViewModel() {
    var streamsList by mutableStateOf<List<StreamItem>>(emptyList())
        private set
    var isLoading by mutableStateOf(false)
        private set

    fun loadStreams(context: Context, categoryType: String, categoryId: String) {
        viewModelScope.launch {
            isLoading = true
            val list = mutableListOf<StreamItem>()

            withContext(Dispatchers.IO) {
                if (categoryId == "favorites") {
                    val allLive = IptvApiClient.getStreams(context, "live", "")
                    val allMovies = IptvApiClient.getStreams(context, "movies", "")
                    val allSeries = IptvApiClient.getStreams(context, "series", "")

                    fun processArray(array: JSONArray, type: String, idKey: String, iconKey: String) {
                        for (i in 0 until array.length()) {
                            val obj = array.getJSONObject(i)
                            val id = obj.optString(idKey, "")
                            val name = obj.optString("name", "عنصر بدون اسم")
                            val icon = obj.optString(iconKey, "")
                            if (id.isNotEmpty() && WatchHistoryManager.isFavorite(context, id)) {
                                list.add(StreamItem(id, name, icon, type))
                            }
                        }
                    }

                    processArray(allLive, "live", "stream_id", "stream_icon")
                    processArray(allMovies, "movies", "stream_id", "stream_icon")
                    processArray(allSeries, "series", "series_id", "cover")
                } else {
                    val result = IptvApiClient.getStreams(context, categoryType, categoryId)
                    for (i in 0 until result.length()) {
                        val obj = result.getJSONObject(i)
                        val id = obj.optString("stream_id").ifEmpty { obj.optString("series_id", "") }
                        val name = obj.optString("name").ifEmpty { obj.optString("title", "عنصر بدون اسم") }
                        val icon = obj.optString("stream_icon").ifEmpty { obj.optString("cover", "") }

                        if (id.isNotEmpty()) {
                            list.add(StreamItem(id, name, icon, categoryType))
                        }
                    }
                }
            }
            streamsList = list
            isLoading = false
        }
    }

    fun toggleFavorite(context: Context, streamId: String) {
        WatchHistoryManager.toggleFavorite(context, streamId)
        // إذا كنا في صفحة المفضلة، نقوم بتحديث القائمة فوراً بحذف العنصر
        streamsList = streamsList.toMutableList().also { /* Logic handled in UI for simplicity or here */ }
    }
}