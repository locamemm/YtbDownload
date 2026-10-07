package com.example.youtubedownload.data.repository

import android.content.Context
import com.example.youtubedownload.data.download.AndroidDownloadManagerHelper
import com.example.youtubedownload.data.local.DownloadHistoryStore
import com.example.youtubedownload.data.model.ConversionUiState
import com.example.youtubedownload.data.model.DownloadHistoryItem
import com.example.youtubedownload.data.model.MediaFormat
import com.example.youtubedownload.data.model.VideoItem
import com.example.youtubedownload.data.network.NetworkClient
import com.example.youtubedownload.data.network.YouTubeParser
import com.google.gson.JsonObject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext

class YouTubeRepository(
    private val context: Context,
    private val historyStore: DownloadHistoryStore = DownloadHistoryStore(context)
) {

    val downloadHistory = historyStore.historyFlow

    /**
     * Searches YouTube videos using YouTube InnerTube API (Primary) with Invidious fallback.
     */
    suspend fun searchVideos(query: String): Result<List<VideoItem>> = withContext(Dispatchers.IO) {
        if (query.isBlank()) {
            return@withContext Result.success(emptyList())
        }

        // 1. Primary Strategy: Official YouTube InnerTube API (Zero API key needed, high reliability)
        try {
            val body = JsonObject().apply {
                val contextObj = JsonObject().apply {
                    val clientObj = JsonObject().apply {
                        addProperty("clientName", "WEB")
                        addProperty("clientVersion", "2.20240101.00.00")
                        addProperty("hl", "en")
                        addProperty("gl", "US")
                    }
                    add("client", clientObj)
                }
                add("context", contextObj)
                addProperty("query", query)
            }

            val responseJson = NetworkClient.youtubeInnerTubeApi.search(body)
            val items = YouTubeParser.parseInnerTubeResponse(responseJson)
            if (items.isNotEmpty()) {
                return@withContext Result.success(items)
            }
        } catch (e: Exception) {
            // Log or proceed to fallback instances
        }

        // 2. Secondary Strategy: Invidious Public Instances Fallback
        var lastException: Throwable? = null
        for (instance in NetworkClient.INVIDIOUS_INSTANCES) {
            try {
                val service = NetworkClient.createInvidiousService(instance)
                val dtoList = service.search(query = query)
                val domainList = dtoList.mapNotNull { it.toDomain() }
                if (domainList.isNotEmpty()) {
                    return@withContext Result.success(domainList)
                }
            } catch (e: Exception) {
                lastException = e
            }
        }

        Result.failure(lastException ?: Exception("No search results found. Please check your network connection."))
    }

    /**
     * Converts and polls Loader.to engine, then hands over completed file to Android DownloadManager.
     */
    fun convertAndDownload(
        video: VideoItem,
        format: MediaFormat
    ): Flow<ConversionUiState> = flow {
        emit(ConversionUiState.Analyzing("Connecting to conversion server..."))

        try {
            // Step 1: Handle HD Thumbnail direct download
            if (format == MediaFormat.THUMBNAIL_HD) {
                emit(ConversionUiState.Enqueueing("Enqueuing HD Thumbnail..."))
                val thumbUrl = video.maxResThumbnailUrl
                val enqueueResult = AndroidDownloadManagerHelper.enqueue(
                    context = context,
                    url = thumbUrl,
                    title = "${video.title}_Thumbnail",
                    extension = format.fileExtension,
                    mimeType = format.mimeType
                )

                enqueueResult.fold(
                    onSuccess = { (downloadId, fileName) ->
                        historyStore.addHistoryItem(
                            DownloadHistoryItem(
                                videoId = video.videoId,
                                title = video.title,
                                author = video.author,
                                thumbnailUrl = video.thumbnailUrl,
                                formatLabel = format.label,
                                formatType = format.type,
                                fileName = fileName,
                                downloadId = downloadId
                            )
                        )
                        emit(ConversionUiState.Success(fileName = fileName, downloadId = downloadId))
                    },
                    onFailure = { err ->
                        emit(ConversionUiState.Error(err.message ?: "Failed to start thumbnail download"))
                    }
                )
                return@flow
            }

            // Step 2: Request conversion from Loader.to
            emit(ConversionUiState.Analyzing("Requesting ${format.label} stream conversion..."))
            val startResp = withContext(Dispatchers.IO) {
                NetworkClient.loaderToApi.startDownload(
                    button = 1,
                    start = 1,
                    end = 1,
                    format = format.formatKey,
                    url = video.cleanUrl
                )
            }

            if (!startResp.isSuccessful && startResp.id.isNullOrEmpty() && startResp.progressUrl.isNullOrEmpty()) {
                emit(ConversionUiState.Error(startResp.text ?: "Server could not initialize conversion. Please try another quality."))
                return@flow
            }

            var downloadUrl = startResp.effectiveDownloadUrl
            val conversionId = startResp.id
            val progressUrl = startResp.progressUrl

            // Step 3: Polling loop if download URL is not immediately ready
            if (downloadUrl.isNullOrEmpty() && (!conversionId.isNullOrEmpty() || !progressUrl.isNullOrEmpty())) {
                var attempts = 0
                val maxAttempts = 60 // 60 * 2 seconds = 2 minutes timeout

                while (downloadUrl.isNullOrEmpty() && attempts < maxAttempts) {
                    delay(2000)
                    attempts++

                    val progressResp = runCatching {
                        withContext(Dispatchers.IO) {
                            if (!progressUrl.isNullOrBlank()) {
                                NetworkClient.loaderToApi.checkProgressByUrl(progressUrl)
                            } else {
                                NetworkClient.loaderToApi.checkProgress(conversionId!!)
                            }
                        }
                    }.getOrNull()

                    if (progressResp != null) {
                        val progress = progressResp.progressPercent
                        val status = progressResp.text ?: "Converting stream: $progress%..."
                        emit(ConversionUiState.Converting(progressPercent = progress, statusText = status))

                        val readyUrl = progressResp.effectiveDownloadUrl
                        if (!readyUrl.isNullOrBlank()) {
                            downloadUrl = readyUrl
                            break
                        }
                    } else {
                        emit(ConversionUiState.Converting(progressPercent = (attempts * 2).coerceAtMost(95), statusText = "Processing media stream..."))
                    }
                }
            }

            if (downloadUrl.isNullOrEmpty()) {
                emit(ConversionUiState.Error("Conversion timed out. The server was busy, please try again."))
                return@flow
            }

            // Step 4: Enqueue final download with Android DownloadManager
            emit(ConversionUiState.Enqueueing("Saving to Downloads directory..."))
            val prefix = "[${format.formatKey.uppercase()}]"
            val enqueueResult = AndroidDownloadManagerHelper.enqueue(
                context = context,
                url = downloadUrl,
                title = "$prefix ${video.title}",
                extension = format.fileExtension,
                mimeType = format.mimeType
            )

            enqueueResult.fold(
                onSuccess = { (downloadId, fileName) ->
                    historyStore.addHistoryItem(
                        DownloadHistoryItem(
                            videoId = video.videoId,
                            title = video.title,
                            author = video.author,
                            thumbnailUrl = video.thumbnailUrl,
                            formatLabel = format.label,
                            formatType = format.type,
                            fileName = fileName,
                            downloadId = downloadId
                        )
                    )
                    emit(ConversionUiState.Success(fileName = fileName, downloadId = downloadId))
                },
                onFailure = { err ->
                    emit(ConversionUiState.Error("DownloadManager error: ${err.localizedMessage}"))
                }
            )

        } catch (e: Exception) {
            emit(ConversionUiState.Error(e.localizedMessage ?: "Unexpected error during conversion"))
        }
    }.flowOn(Dispatchers.Default)

    suspend fun deleteHistory(id: String) {
        historyStore.deleteHistoryItem(id)
    }

    suspend fun clearAllHistory() {
        historyStore.clearHistory()
    }
}
