package com.example.youtubedownload.ui.viewmodel

import android.app.Application
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.youtubedownload.data.model.ConversionUiState
import com.example.youtubedownload.data.model.DownloadHistoryItem
import com.example.youtubedownload.data.model.MediaFormat
import com.example.youtubedownload.data.model.VideoItem
import com.example.youtubedownload.data.repository.YouTubeRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = YouTubeRepository(application.applicationContext)

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _searchResults = MutableStateFlow<List<VideoItem>>(emptyList())
    val searchResults: StateFlow<List<VideoItem>> = _searchResults.asStateFlow()

    private val _isSearching = MutableStateFlow(false)
    val isSearching: StateFlow<Boolean> = _isSearching.asStateFlow()

    private val _searchError = MutableStateFlow<String?>(null)
    val searchError: StateFlow<String?> = _searchError.asStateFlow()

    private val _selectedVideo = MutableStateFlow<VideoItem?>(null)
    val selectedVideo: StateFlow<VideoItem?> = _selectedVideo.asStateFlow()

    private val _conversionState = MutableStateFlow<ConversionUiState>(ConversionUiState.Idle)
    val conversionState: StateFlow<ConversionUiState> = _conversionState.asStateFlow()

    private val _selectedBottomNavTab = MutableStateFlow(0)
    val selectedBottomNavTab: StateFlow<Int> = _selectedBottomNavTab.asStateFlow()

    val downloadHistory: StateFlow<List<DownloadHistoryItem>> = repository.downloadHistory
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    private var searchJob: Job? = null
    private var downloadJob: Job? = null

    init {
        // Pre-load popular / trending topic by default
        search("Trending Music Videos")
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun search(overrideQuery: String? = null) {
        val query = overrideQuery ?: _searchQuery.value.trim()
        if (query.isBlank()) return

        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            _isSearching.value = true
            _searchError.value = null

            val result = repository.searchVideos(query)
            result.fold(
                onSuccess = { items ->
                    _searchResults.value = items
                    if (items.isEmpty()) {
                        _searchError.value = "No videos found for \"$query\". Try different keywords."
                    }
                },
                onFailure = { err ->
                    _searchError.value = err.localizedMessage ?: "Network error. Please try again."
                }
            )
            _isSearching.value = false
        }
    }

    fun selectVideo(video: VideoItem) {
        _selectedVideo.value = video
        _conversionState.value = ConversionUiState.Idle
    }

    fun dismissBottomSheet() {
        if (_conversionState.value is ConversionUiState.Converting || _conversionState.value is ConversionUiState.Analyzing) {
            downloadJob?.cancel()
        }
        _selectedVideo.value = null
        _conversionState.value = ConversionUiState.Idle
    }

    fun startDownload(format: MediaFormat) {
        val video = _selectedVideo.value ?: return

        downloadJob?.cancel()
        downloadJob = viewModelScope.launch {
            repository.convertAndDownload(video, format).collect { state ->
                _conversionState.value = state
            }
        }
    }

    fun copyCleanUrl(context: Context, video: VideoItem) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("YouTube URL", video.cleanUrl)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(context, "Clean URL copied to clipboard!", Toast.LENGTH_SHORT).show()
    }

    fun deleteHistoryItem(id: String) {
        viewModelScope.launch {
            repository.deleteHistory(id)
        }
    }

    fun clearAllHistory() {
        viewModelScope.launch {
            repository.clearAllHistory()
        }
    }

    fun selectTab(tab: Int) {
        _selectedBottomNavTab.value = tab
    }
}
