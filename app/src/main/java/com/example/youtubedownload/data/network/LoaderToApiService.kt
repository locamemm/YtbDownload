package com.example.youtubedownload.data.network

import com.example.youtubedownload.data.model.LoaderProgressResponse
import com.example.youtubedownload.data.model.LoaderStartResponse
import retrofit2.http.GET
import retrofit2.http.Query
import retrofit2.http.Url

interface LoaderToApiService {
    @GET("ajax/download.php")
    suspend fun startDownload(
        @Query("button") button: Int = 1,
        @Query("start") start: Int = 1,
        @Query("end") end: Int = 1,
        @Query("format") format: String,
        @Query("url") url: String
    ): LoaderStartResponse

    @GET("ajax/progress.php")
    suspend fun checkProgress(
        @Query("id") id: String
    ): LoaderProgressResponse

    @GET
    suspend fun checkProgressByUrl(
        @Url progressUrl: String
    ): LoaderProgressResponse
}
