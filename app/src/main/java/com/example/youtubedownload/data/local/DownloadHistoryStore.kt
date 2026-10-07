package com.example.youtubedownload.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.youtubedownload.data.model.DownloadHistoryItem
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "download_history_prefs")

class DownloadHistoryStore(private val context: Context) {

    private val gson = Gson()
    private val historyKey = stringPreferencesKey("saved_download_history")

    val historyFlow: Flow<List<DownloadHistoryItem>> = context.dataStore.data.map { preferences ->
        val json = preferences[historyKey]
        if (json.isNullOrBlank()) {
            emptyList()
        } else {
            try {
                val listType = object : TypeToken<List<DownloadHistoryItem>>() {}.type
                gson.fromJson<List<DownloadHistoryItem>>(json, listType) ?: emptyList()
            } catch (e: Exception) {
                emptyList()
            }
        }
    }

    suspend fun addHistoryItem(item: DownloadHistoryItem) {
        context.dataStore.edit { preferences ->
            val json = preferences[historyKey]
            val currentList: MutableList<DownloadHistoryItem> = if (json.isNullOrBlank()) {
                mutableListOf()
            } else {
                try {
                    val listType = object : TypeToken<List<DownloadHistoryItem>>() {}.type
                    (gson.fromJson<List<DownloadHistoryItem>>(json, listType) ?: emptyList()).toMutableList()
                } catch (e: Exception) {
                    mutableListOf()
                }
            }

            // Put latest item on top and remove any duplicate id
            currentList.removeAll { it.id == item.id }
            currentList.add(0, item)

            // Keep max 100 recent items
            val trimmedList = currentList.take(100)
            preferences[historyKey] = gson.toJson(trimmedList)
        }
    }

    suspend fun deleteHistoryItem(id: String) {
        context.dataStore.edit { preferences ->
            val json = preferences[historyKey] ?: return@edit
            try {
                val listType = object : TypeToken<List<DownloadHistoryItem>>() {}.type
                val currentList: List<DownloadHistoryItem> = gson.fromJson(json, listType) ?: emptyList()
                val updatedList = currentList.filterNot { it.id == id }
                preferences[historyKey] = gson.toJson(updatedList)
            } catch (e: Exception) {
                // ignore
            }
        }
    }

    suspend fun clearHistory() {
        context.dataStore.edit { preferences ->
            preferences.remove(historyKey)
        }
    }
}
