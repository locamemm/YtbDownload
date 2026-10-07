package com.example.youtubedownload.data.network

import com.google.gson.JsonObject
import retrofit2.http.Body
import retrofit2.http.Headers
import retrofit2.http.POST

interface YouTubeInnerTubeService {
    @Headers(
        "Content-Type: application/json",
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    )
    @POST("youtubei/v1/search")
    suspend fun search(
        @Body body: JsonObject
    ): JsonObject
}
