package com.example.youtubedownload.data.model

import com.google.gson.annotations.SerializedName
import java.util.Locale

/**
 * Domain model representing a YouTube video result.
 */
data class VideoItem(
    val videoId: String,
    val title: String,
    val author: String,
    val authorId: String? = null,
    val lengthSeconds: Long = 0L,
    val thumbnailUrl: String,
    val viewCount: Long? = null,
    val publishedText: String? = null,
    val durationText: String? = null,
    val viewsText: String? = null
) {
    val cleanUrl: String
        get() = "https://www.youtube.com/watch?v=$videoId"

    val maxResThumbnailUrl: String
        get() = "https://i.ytimg.com/vi/$videoId/maxresdefault.jpg"

    val hqThumbnailUrl: String
        get() = "https://i.ytimg.com/vi/$videoId/hqdefault.jpg"

    val formattedDuration: String
        get() {
            if (!durationText.isNullOrBlank()) return durationText
            if (lengthSeconds <= 0) return "Live / Unknown"
            val hours = lengthSeconds / 3600
            val minutes = (lengthSeconds % 3600) / 60
            val seconds = lengthSeconds % 60
            return if (hours > 0) {
                String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format(Locale.US, "%02d:%02d", minutes, seconds)
            }
        }

    val formattedViews: String
        get() {
            if (!viewsText.isNullOrBlank()) return viewsText
            val count = viewCount ?: return ""
            return when {
                count >= 1_000_000_000 -> String.format(Locale.US, "%.1fB views", count / 1_000_000_000.0)
                count >= 1_000_000 -> String.format(Locale.US, "%.1fM views", count / 1_000_000.0)
                count >= 1_000 -> String.format(Locale.US, "%.1fK views", count / 1_000.0)
                else -> "$count views"
            }
        }
}

/**
 * Raw DTO matching Invidious API search response
 */
data class InvidiousVideoDto(
    @SerializedName("type") val type: String? = null,
    @SerializedName("title") val title: String? = null,
    @SerializedName("videoId") val videoId: String? = null,
    @SerializedName("author") val author: String? = null,
    @SerializedName("authorId") val authorId: String? = null,
    @SerializedName("videoThumbnails") val videoThumbnails: List<InvidiousThumbnailDto>? = null,
    @SerializedName("lengthSeconds") val lengthSeconds: Long? = null,
    @SerializedName("viewCount") val viewCount: Long? = null,
    @SerializedName("publishedText") val publishedText: String? = null
) {
    fun toDomain(): VideoItem? {
        val id = videoId ?: return null
        val bestThumbnail = videoThumbnails
            ?.firstOrNull { it.quality == "maxresdefault" || it.quality == "high" }
            ?.url
            ?: videoThumbnails?.firstOrNull()?.url
            ?: "https://i.ytimg.com/vi/$id/hqdefault.jpg"

        val sanitizedThumbnail = if (bestThumbnail.startsWith("//")) {
            "https:$bestThumbnail"
        } else bestThumbnail

        return VideoItem(
            videoId = id,
            title = title?.trim() ?: "Untitled Video",
            author = author?.trim() ?: "Unknown Channel",
            authorId = authorId,
            lengthSeconds = lengthSeconds ?: 0L,
            thumbnailUrl = sanitizedThumbnail,
            viewCount = viewCount,
            publishedText = publishedText
        )
    }
}

data class InvidiousThumbnailDto(
    @SerializedName("quality") val quality: String? = null,
    @SerializedName("url") val url: String? = null,
    @SerializedName("width") val width: Int? = null,
    @SerializedName("height") val height: Int? = null
)
