package com.example.youtubedownload.data.model

import com.google.gson.annotations.SerializedName

enum class FormatType {
    VIDEO,
    AUDIO,
    UTILITY
}

enum class MediaFormat(
    val formatKey: String,
    val label: String,
    val subLabel: String,
    val type: FormatType,
    val fileExtension: String,
    val mimeType: String
) {
    // Video Formats
    VIDEO_1080(
        formatKey = "1080",
        label = "1080p FHD",
        subLabel = "MP4 • High Definition",
        type = FormatType.VIDEO,
        fileExtension = "mp4",
        mimeType = "video/mp4"
    ),
    VIDEO_720(
        formatKey = "720",
        label = "720p HD",
        subLabel = "MP4 • Standard HD",
        type = FormatType.VIDEO,
        fileExtension = "mp4",
        mimeType = "video/mp4"
    ),
    VIDEO_480(
        formatKey = "480",
        label = "480p",
        subLabel = "MP4 • Medium",
        type = FormatType.VIDEO,
        fileExtension = "mp4",
        mimeType = "video/mp4"
    ),
    VIDEO_360(
        formatKey = "360",
        label = "360p",
        subLabel = "MP4 • Low data",
        type = FormatType.VIDEO,
        fileExtension = "mp4",
        mimeType = "video/mp4"
    ),

    // Audio Formats
    AUDIO_MP3(
        formatKey = "mp3",
        label = "MP3",
        subLabel = "320 kbps • High Quality",
        type = FormatType.AUDIO,
        fileExtension = "mp3",
        mimeType = "audio/mpeg"
    ),
    AUDIO_M4A(
        formatKey = "m4a",
        label = "M4A",
        subLabel = "AAC • Crisp Audio",
        type = FormatType.AUDIO,
        fileExtension = "m4a",
        mimeType = "audio/mp4"
    ),
    AUDIO_WAV(
        formatKey = "wav",
        label = "WAV",
        subLabel = "Lossless Audio",
        type = FormatType.AUDIO,
        fileExtension = "wav",
        mimeType = "audio/wav"
    ),

    // Utilities
    THUMBNAIL_HD(
        formatKey = "thumbnail",
        label = "HD Thumbnail",
        subLabel = "MaxRes 1080p JPG",
        type = FormatType.UTILITY,
        fileExtension = "jpg",
        mimeType = "image/jpeg"
    )
}

/**
 * Response from Loader.to download request
 */
data class LoaderStartResponse(
    @SerializedName("success") val success: Any? = null,
    @SerializedName("id") val id: String? = null,
    @SerializedName("text") val text: String? = null,
    @SerializedName("download_url") val downloadUrl: String? = null,
    @SerializedName("url") val url: String? = null,
    @SerializedName("progress_url") val progressUrl: String? = null
) {
    val isSuccessful: Boolean
        get() = when (success) {
            is Boolean -> success
            is Number -> success.toInt() != 0
            is String -> success.equals("true", ignoreCase = true) || success == "1"
            else -> !id.isNullOrEmpty()
        }

    val effectiveDownloadUrl: String?
        get() = downloadUrl?.takeIf { it.isNotBlank() && it != "null" }
            ?: url?.takeIf { it.isNotBlank() && it != "null" }
}

/**
 * Response from Loader.to progress polling
 */
data class LoaderProgressResponse(
    @SerializedName("success") val success: Any? = null,
    @SerializedName("progress") val progress: Int? = null, // 0 to 1000 (1000 = 100.0%)
    @SerializedName("text") val text: String? = null,
    @SerializedName("download_url") val downloadUrl: String? = null,
    @SerializedName("url") val url: String? = null
) {
    val effectiveDownloadUrl: String?
        get() = downloadUrl?.takeIf { it.isNotBlank() && it != "null" }
            ?: url?.takeIf { it.isNotBlank() && it != "null" }

    val isCompleted: Boolean
        get() = !effectiveDownloadUrl.isNullOrEmpty() || (progress ?: 0) >= 1000

    val progressPercent: Int
        get() {
            val p = progress ?: 0
            return (p / 10).coerceIn(0, 100)
        }
}

/**
 * UI State for conversion modal sheet
 */
sealed interface ConversionUiState {
    object Idle : ConversionUiState
    data class Analyzing(val message: String = "Analyzing video link...") : ConversionUiState
    data class Converting(val progressPercent: Int, val statusText: String) : ConversionUiState
    data class Enqueueing(val message: String = "Sending to DownloadManager...") : ConversionUiState
    data class Success(val fileName: String, val downloadId: Long) : ConversionUiState
    data class Error(val message: String) : ConversionUiState
}
