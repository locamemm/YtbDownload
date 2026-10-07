package com.example.youtubedownload.data.network

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object NetworkClient {

    private const val DEFAULT_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

    val INVIDIOUS_INSTANCES = listOf(
        "https://inv.vern.cc/",
        "https://invidious.asir.dev/",
        "https://invidious.fdn.fr/",
        "https://yt.drgnz.club/"
    )

    private val gson: Gson = GsonBuilder()
        .setLenient()
        .create()

    private val userAgentInterceptor = Interceptor { chain ->
        val original = chain.request()
        val requestWithHeaders = original.newBuilder()
            .header("User-Agent", DEFAULT_USER_AGENT)
            .header("Accept", "application/json, text/plain, */*")
            .build()
        chain.proceed(requestWithHeaders)
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BASIC
    }

    val okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .addInterceptor(userAgentInterceptor)
        .addInterceptor(loggingInterceptor)
        .retryOnConnectionFailure(true)
        .build()

    val youtubeInnerTubeApi: YouTubeInnerTubeService by lazy {
        Retrofit.Builder()
            .baseUrl("https://www.youtube.com/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(YouTubeInnerTubeService::class.java)
    }

    val loaderToApi: LoaderToApiService by lazy {
        Retrofit.Builder()
            .baseUrl("https://loader.to/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(LoaderToApiService::class.java)
    }

    fun createInvidiousService(baseUrl: String): InvidiousApiService {
        val sanitizedBaseUrl = if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
        return Retrofit.Builder()
            .baseUrl(sanitizedBaseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(InvidiousApiService::class.java)
    }
}
