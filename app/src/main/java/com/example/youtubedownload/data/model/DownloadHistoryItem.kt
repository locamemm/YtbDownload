package com.example.youtubedownload.data.model

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/**
 * Model representing a record in the user's download history.
 */
data class DownloadHistoryItem(
    val id: String = UUID.randomUUID().toString(),
    val videoId: String,
    val title: String,
    val author: String,
    val thumbnailUrl: String,
    val formatLabel: String,
    val formatType: FormatType,
    val fileName: String,
    val downloadId: Long,
    val timestamp: Long = System.currentTimeMillis()
) {
    val formattedDate: String
        get() {
            val sdf = SimpleDateFormat("MMM dd, yyyy • HH:mm", Locale.getDefault())
            return sdf.format(Date(timestamp))
        }
}
