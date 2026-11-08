package com.example.smartiptv

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

object IptvApiClient {

    private const val DEFAULT_HOST = "http://169.58.114.30:8080"

    fun verifyActivationCode(context: Context?, code: String): String {
        return try {
            val urlString = "$DEFAULT_HOST/player_api.php?username=$code&password=$code"
            val url = URL(urlString)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 8000
            connection.readTimeout = 8000
            connection.doInput = true
            connection.connect()

            val responseCode = connection.responseCode
            val inputStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }

            val reader = BufferedReader(InputStreamReader(inputStream))
            val response = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                response.append(line)
            }
            reader.close()
            response.toString()
        } catch (e: Exception) {
            "{\"error\": \"${e.javaClass.simpleName}: ${e.localizedMessage}\"}"
        }
    }

    fun getCategories(context: Context, action: String): String {
        return try {
            val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
            val code = prefs.getString("activation_code", "") ?: ""

            val urlStr = "$DEFAULT_HOST/player_api.php?username=$code&password=$code&action=$action"
            val url = URL(urlStr)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.doInput = true
            connection.connect()

            val responseCode = connection.responseCode
            val inputStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            "[]"
        }
    }

    fun getCategoriesWithCache(context: Context, action: String): String {
        when (action) {
            "get_live_categories" -> if (IptvCacheManager.liveCategoriesCache != null) return IptvCacheManager.liveCategoriesCache!!
            "get_vod_categories" -> if (IptvCacheManager.movieCategoriesCache != null) return IptvCacheManager.movieCategoriesCache!!
            "get_series_categories" -> if (IptvCacheManager.seriesCategoriesCache != null) return IptvCacheManager.seriesCategoriesCache!!
        }

        val result = getCategories(context, action)
        when (action) {
            "get_live_categories" -> IptvCacheManager.liveCategoriesCache = result
            "get_vod_categories" -> IptvCacheManager.movieCategoriesCache = result
            "get_series_categories" -> IptvCacheManager.seriesCategoriesCache = result
        }
        return result
    }

    fun getStreams(context: Context, type: String, categoryId: String): JSONArray {
        return try {
            val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
            val code = prefs.getString("activation_code", "") ?: ""

            val action = when (type) {
                "live" -> "get_live_streams"
                "movies" -> "get_vod_streams"
                "series" -> "get_series"
                else -> "get_live_streams"
            }

            val urlStr = if (categoryId.isEmpty() || categoryId == "favorites") {
                "$DEFAULT_HOST/player_api.php?username=$code&password=$code&action=$action"
            } else {
                "$DEFAULT_HOST/player_api.php?username=$code&password=$code&action=$action&category_id=$categoryId"
            }

            val url = URL(urlStr)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 12000
            connection.readTimeout = 12000
            connection.doInput = true
            connection.connect()

            val responseCode = connection.responseCode
            val inputStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            val response = inputStream.bufferedReader().use { it.readText() }

            if (response.trim().startsWith("[")) {
                val jsonArray = JSONArray(response)
                if (categoryId.isNotEmpty() && categoryId != "favorites") {
                    val filteredArray = JSONArray()
                    for (i in 0 until jsonArray.length()) {
                        val obj = jsonArray.getJSONObject(i)
                        val cat = obj.optString("category_id", "")
                        if (cat == categoryId) {
                            filteredArray.put(obj)
                        }
                    }
                    if (filteredArray.length() > 0) filteredArray else jsonArray
                } else {
                    jsonArray
                }
            } else {
                JSONArray()
            }
        } catch (e: Exception) {
            JSONArray()
        }
    }

    fun getStreamsWithCache(context: Context, type: String, categoryId: String): JSONArray {
        if (categoryId.isEmpty() || categoryId == "favorites") {
            when (type) {
                "live" -> if (IptvCacheManager.liveStreamsCache != null) return IptvCacheManager.liveStreamsCache!!
                "movies" -> if (IptvCacheManager.movieStreamsCache != null) return IptvCacheManager.movieStreamsCache!!
                "series" -> if (IptvCacheManager.seriesCache != null) return IptvCacheManager.seriesCache!!
            }
        }

        val array = getStreams(context, type, categoryId)

        if (categoryId.isEmpty() || categoryId == "favorites") {
            when (type) {
                "live" -> IptvCacheManager.liveStreamsCache = array
                "movies" -> IptvCacheManager.movieStreamsCache = array
                "series" -> IptvCacheManager.seriesCache = array
            }
        }
        return array
    }

    fun getSeriesInfo(context: Context, seriesId: String): String {
        return try {
            val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
            val code = prefs.getString("activation_code", "") ?: ""
            val urlStr = "$DEFAULT_HOST/player_api.php?username=$code&password=$code&action=get_series_info&series_id=$seriesId"
            val url = URL(urlStr)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.doInput = true
            connection.connect()

            val responseCode = connection.responseCode
            val inputStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            "{}"
        }
    }

    fun getVodInfo(context: Context, vodId: String): String {
        return try {
            val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
            val code = prefs.getString("activation_code", "") ?: ""
            val urlStr = "$DEFAULT_HOST/player_api.php?username=$code&password=$code&action=get_vod_info&vod_id=$vodId"
            val url = URL(urlStr)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.doInput = true
            connection.connect()

            val responseCode = connection.responseCode
            val inputStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            "{}"
        }
    }

    fun getStreamUrl(context: Context, type: String, streamId: String): String {
        val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
        val code = prefs.getString("activation_code", "") ?: ""

        return when (type) {
            "live" -> "$DEFAULT_HOST/live/$code/$code/$streamId.ts"
            "movies" -> "$DEFAULT_HOST/movie/$code/$code/$streamId.mp4"
            "series" -> "$DEFAULT_HOST/series/$code/$code/$streamId.mp4"
            else -> "$DEFAULT_HOST/live/$code/$code/$streamId.ts"
        }
    }

    fun getCatchupUrl(context: Context, streamId: String, startTimestamp: String): String {
        val prefs = context.getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
        val code = prefs.getString("activation_code", "") ?: ""
        return "$DEFAULT_HOST/live/$code/$code/$streamId.ts?start=$startTimestamp"
    }
}