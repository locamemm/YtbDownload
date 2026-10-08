package com.example.youtubedownload.data.download

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.widget.Toast

object AndroidDownloadManagerHelper {

    /**
     * Sanitizes a string so it can be safely used as a file name across Android storage systems.
     */
    fun sanitizeFileName(rawTitle: String, extension: String): String {
        val cleanTitle = rawTitle
            .replace(Regex("[\\\\/:*?\"<>|]"), "_")
            .replace(Regex("\\s+"), " ")
            .trim()
            .take(80)

        val finalName = if (cleanTitle.isEmpty()) "YouTube_Media" else cleanTitle
        val cleanExt = extension.removePrefix(".")
        return "$finalName.$cleanExt"
    }

    /**
     * Enqueues a download with Android's system DownloadManager into Environment.DIRECTORY_DOWNLOADS.
     */
    fun enqueue(
        context: Context,
        url: String,
        title: String,
        extension: String,
        mimeType: String
    ): Result<Pair<Long, String>> {
        return runCatching {
            val fileName = sanitizeFileName(title, extension)
            val uri = Uri.parse(url)

            val cleanExt = extension.removePrefix(".").lowercase()
            val resolvedMimeType = when (cleanExt) {
                "m4a" -> "audio/x-m4a"
                "aac" -> "audio/aac"
                "mp3" -> "audio/mpeg"
                "wav" -> "audio/wav"
                "mp4" -> "video/mp4"
                "jpg", "jpeg" -> "image/jpeg"
                else -> mimeType
            }

            val request = DownloadManager.Request(uri).apply {
                setTitle(fileName)
                setDescription("Downloading YouTube Media...")
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setAllowedOverMetered(true)
                setAllowedOverRoaming(true)
                addRequestHeader("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36")
                addRequestHeader("Referer", "https://loader.to/")
                setMimeType(resolvedMimeType)
                setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_DOWNLOADS,
                    "YouTubeDownloads/$fileName"
                )
            }

            val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val downloadId = downloadManager.enqueue(request)

            Pair(downloadId, fileName)
        }
    }

    /**
     * Opens the device's default Downloads screen.
     */
    fun openDownloadsFolder(context: Context) {
        try {
            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(context, "Saved to Downloads/YouTubeDownloads", Toast.LENGTH_SHORT).show()
        }
    }
}
