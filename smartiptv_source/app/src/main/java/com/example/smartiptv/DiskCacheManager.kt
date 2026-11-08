package com.example.smartiptv

import android.content.Context
import java.io.File

object DiskCacheManager {
    fun saveData(context: Context, fileName: String, data: String) {
        try {
            val file = File(context.cacheDir, "$fileName.json")
            file.writeText(data)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun loadData(context: Context, fileName: String): String? {
        try {
            val file = File(context.cacheDir, "$fileName.json")
            if (file.exists() && file.length() > 0) {
                return file.readText()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}