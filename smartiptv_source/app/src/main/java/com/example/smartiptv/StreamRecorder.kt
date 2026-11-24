package com.example.smartiptv

import android.content.Context
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.URL

object StreamRecorder {
    suspend fun downloadStream(context: Context, streamUrl: String, fileName: String, onComplete: (Boolean) -> Unit) {
        withContext(Dispatchers.IO) {
            try {
                val url = URL(streamUrl)
                val connection = url.openConnection()
                connection.connect()
                val inputStream = connection.getInputStream()

                val downloadsDir = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)
                val file = File(downloadsDir, "$fileName.ts")
                val outputStream = FileOutputStream(file)

                val buffer = ByteArray(4096)
                var bytesRead: Int
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                }
                outputStream.close()
                inputStream.close()
                withContext(Dispatchers.Main) { onComplete(true) }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) { onComplete(false) }
            }
        }
    }
}