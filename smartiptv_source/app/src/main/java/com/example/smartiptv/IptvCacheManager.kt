package com.example.smartiptv

import org.json.JSONArray

object IptvCacheManager {
    var liveStreamsCache: JSONArray? = null
    var movieStreamsCache: JSONArray? = null
    var seriesCache: JSONArray? = null

    var liveCategoriesCache: String? = null
    var movieCategoriesCache: String? = null
    var seriesCategoriesCache: String? = null

    fun clearAll() {
        liveStreamsCache = null
        movieStreamsCache = null
        seriesCache = null
        liveCategoriesCache = null
        movieCategoriesCache = null
        seriesCategoriesCache = null
    }
}
