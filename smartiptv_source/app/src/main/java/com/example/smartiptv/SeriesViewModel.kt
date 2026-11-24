package com.example.smartiptv

import android.content.Context
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

class SeriesViewModel : ViewModel() {
    val details: MutableState<SeriesDetails?> = mutableStateOf(null)
    val isLoading: MutableState<Boolean> = mutableStateOf(false)
    val selectedSeason: MutableState<String> = mutableStateOf("")

    fun loadSeriesInfo(context: Context, seriesId: String) {
        // Clear previous series info immediately to prevent flickering or wrong data
        details.value = null
        isLoading.value = true
        
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val jsonStr = IptvApiClient.getSeriesInfo(context, seriesId)
                try {
                    val jsonObj = JSONObject(jsonStr)
                    val info = jsonObj.optJSONObject("info")
                    val cover = info?.optString("cover") ?: ""
                    val plot = info?.optString("plot") ?: ""

                    val episodesObj = jsonObj.optJSONObject("episodes")
                    val map = mutableMapOf<String, List<EpisodeItem>>()
                    val seasons = mutableListOf<String>()

                    if (episodesObj != null) {
                        val keys = episodesObj.keys()
                        while (keys.hasNext()) {
                            val seasonNum = keys.next()
                            seasons.add(seasonNum)
                            val epArray = episodesObj.optJSONArray(seasonNum)
                            val eps = mutableListOf<EpisodeItem>()
                            if (epArray != null) {
                                for (i in 0 until epArray.length()) {
                                    val ep = epArray.getJSONObject(i)
                                    val id = ep.optString("id", "")
                                    val epNum = ep.optString("episode_num", "")
                                    val title = ep.optString("title", "Episode $epNum")
                                    val ext = ep.optString("container_extension", "mp4")
                                    val epCover = ep.optString("info", "").ifEmpty { cover }
                                    eps.add(EpisodeItem(id, epNum, title, ext, epCover))
                                }
                            }
                            map[seasonNum] = eps
                        }
                    }
                    val sortedSeasons = seasons.sortedBy { it.toIntOrNull() ?: 0 }
                    val result = SeriesDetails(cover, plot, map, sortedSeasons)
                    
                    withContext(Dispatchers.Main) {
                        details.value = result
                        if (sortedSeasons.isNotEmpty()) {
                            selectedSeason.value = sortedSeasons[0]
                        }
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) { details.value = null }
                }
            }
            isLoading.value = false
        }
    }

    fun selectSeason(season: String) {
        selectedSeason.value = season
    }
}
