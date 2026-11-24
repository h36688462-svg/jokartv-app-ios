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
import org.json.JSONObject

class DashboardViewModel : ViewModel() {

    var categoriesData by mutableStateOf<List<DashboardCategory>>(emptyList())
        private set

    var recentItems by mutableStateOf<List<StreamItem>>(emptyList())
        private set

    var featuredItem by mutableStateOf<StreamItem?>(null)
        private set

    var isLoading by mutableStateOf(false)
        private set

    fun loadData(context: Context, selectedTab: String) {
        viewModelScope.launch {
            isLoading = true
            
            // تحميل السجل الأخير دائماً
            recentItems = WatchHistoryManager.getRecent(context)

            if (selectedTab == "favorites") {
                val list = mutableListOf<StreamItem>()
                withContext(Dispatchers.IO) {
                    val allLive = IptvApiClient.getStreamsWithCache(context, "live", "")
                    val allMovies = IptvApiClient.getStreamsWithCache(context, "movies", "")
                    val allSeries = IptvApiClient.getStreamsWithCache(context, "series", "")

                    fun processArray(array: JSONArray, type: String, idKey: String, iconKey: String) {
                        for (i in 0 until array.length()) {
                            val obj = array.getJSONObject(i)
                            val id = obj.optString(idKey, "")
                            if (id.isNotEmpty() && WatchHistoryManager.isFavorite(context, id)) {
                                list.add(StreamItem(id, obj.optString("name"), obj.optString(iconKey), type))
                            }
                        }
                    }
                    processArray(allLive, "live", "stream_id", "stream_icon")
                    processArray(allMovies, "movies", "stream_id", "stream_icon")
                    processArray(allSeries, "series", "series_id", "cover")
                }
                categoriesData = listOf(DashboardCategory("fav", "المفضلة ❤️", list))
                featuredItem = list.firstOrNull()
            } else {
                val type = when (selectedTab) {
                    "series" -> "series"
                    "live" -> "live"
                    else -> "movies"
                }
                val catAction = when (selectedTab) {
                    "series" -> "get_series_categories"
                    "live" -> "get_live_categories"
                    else -> "get_vod_categories"
                }

                val resultCats = withContext(Dispatchers.IO) {
                    val catJson = IptvApiClient.getCategoriesWithCache(context, catAction)
                    val catArray = try { JSONArray(catJson) } catch (_: Exception) { JSONArray() }
                    val allStreamsJson = IptvApiClient.getStreamsWithCache(context, type, "")

                    val streamsByCategory = mutableMapOf<String, MutableList<JSONObject>>()
                    for (i in 0 until allStreamsJson.length()) {
                        val obj = allStreamsJson.getJSONObject(i)
                        val catId = obj.optString("category_id", "")
                        if (catId.isNotEmpty()) {
                            streamsByCategory.getOrPut(catId) { mutableListOf() }.add(obj)
                        }
                    }

                    val list = mutableListOf<DashboardCategory>()
                    for (c in 0 until catArray.length()) {
                        val catObj = catArray.getJSONObject(c)
                        val catId = catObj.optString("category_id", "")
                        val catName = catObj.optString("category_name", "قسم")
                        val catStreams = streamsByCategory[catId] ?: emptyList()
                        
                        val sList = catStreams.take(15).map { sObj ->
                            val sId = sObj.optString("stream_id").ifEmpty { sObj.optString("series_id", "") }
                            val sName = sObj.optString("name").ifEmpty { sObj.optString("title", "") }
                            val sIcon = sObj.optString("stream_icon").ifEmpty { sObj.optString("cover", "") }
                            StreamItem(sId, sName, sIcon, type)
                        }
                        if (sList.isNotEmpty()) list.add(DashboardCategory(catId, catName, sList))
                    }
                    list
                }
                categoriesData = resultCats
                featuredItem = resultCats.firstOrNull()?.items?.firstOrNull()
            }
            isLoading = false
        }
    }
}