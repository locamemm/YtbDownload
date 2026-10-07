package com.example.youtubedownload.data.network

import com.example.youtubedownload.data.model.InvidiousVideoDto
import retrofit2.http.GET
import retrofit2.http.Query

interface InvidiousApiService {
    @GET("api/v1/search")
    suspend fun search(
        @Query("q") query: String,
        @Query("type") type: String = "video"
    ): List<InvidiousVideoDto>
}
