package com.example.youtubedownload

import com.example.youtubedownload.data.network.NetworkClient
import com.example.youtubedownload.data.network.YouTubeParser
import com.google.gson.JsonObject
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test

class ExampleUnitTest {
    @Test
    fun testLiveYouTubeSearch() = runBlocking {
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
            addProperty("query", "Taylor Swift")
        }

        val json = NetworkClient.youtubeInnerTubeApi.search(body)
        println("Response received! keys = " + json.keySet())
        val items = YouTubeParser.parseInnerTubeResponse(json)
        println("Parsed items count: " + items.size)
        items.take(3).forEach {
            println("Item: ${it.videoId} | ${it.title} | ${it.author}")
        }
        assertTrue("Expected items > 0, got ${items.size}", items.isNotEmpty())
    }
}