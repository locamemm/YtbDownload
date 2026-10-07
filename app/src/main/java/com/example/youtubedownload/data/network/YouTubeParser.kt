package com.example.youtubedownload.data.network

import com.example.youtubedownload.data.model.VideoItem
import com.google.gson.JsonObject

object YouTubeParser {

    /**
     * Parses the official YouTube InnerTube API search response.
     */
    fun parseInnerTubeResponse(root: JsonObject): List<VideoItem> {
        val results = mutableListOf<VideoItem>()
        try {
            val sections = root.getAsJsonObject("contents")
                ?.getAsJsonObject("twoColumnSearchResultsRenderer")
                ?.getAsJsonObject("primaryContents")
                ?.getAsJsonObject("sectionListRenderer")
                ?.getAsJsonArray("contents") ?: return results

            for (sectionElem in sections) {
                val itemSection = sectionElem.asJsonObject?.getAsJsonObject("itemSectionRenderer")
                val itemContents = itemSection?.getAsJsonArray("contents") ?: continue

                for (contentElem in itemContents) {
                    val vr = contentElem.asJsonObject?.getAsJsonObject("videoRenderer") ?: continue
                    val videoId = vr.get("videoId")?.asString ?: continue

                    // Extract Title
                    val title = vr.getAsJsonObject("title")
                        ?.getAsJsonArray("runs")
                        ?.joinToString("") { it.asJsonObject?.get("text")?.asString ?: "" }
                        ?.ifBlank { "Untitled Video" } ?: "Untitled Video"

                    // Extract Author / Channel
                    val author = vr.getAsJsonObject("ownerText")
                        ?.getAsJsonArray("runs")
                        ?.joinToString("") { it.asJsonObject?.get("text")?.asString ?: "" }
                        ?.ifBlank { "YouTube Creator" } ?: "YouTube Creator"

                    // Extract Duration
                    val lengthText = vr.getAsJsonObject("lengthText")?.get("simpleText")?.asString ?: ""
                    val lengthSeconds = parseDurationToSeconds(lengthText)

                    // Extract Views
                    val viewsText = vr.getAsJsonObject("shortViewCountText")?.get("simpleText")?.asString

                    // Extract Published
                    val publishedText = vr.getAsJsonObject("publishedTimeText")?.get("simpleText")?.asString

                    // Extract Thumbnail
                    val thumbnails = vr.getAsJsonObject("thumbnail")?.getAsJsonArray("thumbnails")
                    val bestThumbnail = thumbnails?.lastOrNull()?.asJsonObject?.get("url")?.asString
                        ?: "https://i.ytimg.com/vi/$videoId/hqdefault.jpg"

                    results.add(
                        VideoItem(
                            videoId = videoId,
                            title = title.trim(),
                            author = author.trim(),
                            lengthSeconds = lengthSeconds,
                            thumbnailUrl = bestThumbnail,
                            viewCount = null,
                            publishedText = publishedText,
                            durationText = lengthText.ifBlank { null },
                            viewsText = viewsText
                        )
                    )
                }
            }
        } catch (e: Exception) {
            // gracefully return whatever was parsed
        }
        return results.distinctBy { it.videoId }
    }

    private fun parseDurationToSeconds(text: String): Long {
        if (text.isBlank()) return 0L
        val parts = text.split(":").mapNotNull { it.trim().toLongOrNull() }
        return when (parts.size) {
            3 -> parts[0] * 3600 + parts[1] * 60 + parts[2]
            2 -> parts[0] * 60 + parts[1]
            1 -> parts[0]
            else -> 0L
        }
    }
}
