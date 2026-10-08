import Foundation
import SwiftUI
import Combine

@MainActor
public final class YouTubeViewModel: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public var searchResults: [VideoItem] = []
    @Published public var isSearching: Bool = false
    @Published public var searchError: String? = nil

    @Published public var selectedVideo: VideoItem? = nil
    @Published public var showDownloadSheet: Bool = false
    @Published public var conversionState: ConversionState = .idle

    @Published public var historyItems: [DownloadHistoryItem] = []
    @Published public var alertMessage: String? = nil
    @Published public var showAlert: Bool = false

    private let historyStorageKey = "YouTubeDownload_History_Storage"

    public init() {
        loadHistory()
        loadInitialTrending()
    }

    // MARK: - Initial trending or quick search
    public func loadInitialTrending() {
        guard searchResults.isEmpty else { return }
        search(keyword: "Trending Music Vietnam 2024")
    }

    // MARK: - Search
    public func search(keyword: String? = nil) {
        let query = (keyword ?? searchQuery).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        if let keyword = keyword {
            self.searchQuery = keyword
        }

        isSearching = true
        searchError = nil

        Task {
            do {
                let results = try await NetworkService.shared.searchVideos(query: query)
                self.searchResults = results
                self.isSearching = false
                if results.isEmpty {
                    self.searchError = "No videos found for \"\(query)\". Try another keyword."
                }
            } catch {
                self.isSearching = false
                self.searchError = error.localizedDescription
            }
        }
    }

    // MARK: - Select Video for Download
    public func selectVideo(_ video: VideoItem) {
        self.selectedVideo = video
        self.conversionState = .idle
        self.showDownloadSheet = true
    }

    // MARK: - Conversion and Download Workflow
    public func startDownload(format: MediaFormat) {
        guard let video = selectedVideo else { return }

        conversionState = .analyzing("Connecting to conversion server...")

        Task {
            do {
                // 1. Direct Thumbnail Download
                if format.type == .utility {
                    guard let thumbUrl = URL(string: video.maxResThumbnailUrl.isEmpty ? video.thumbnailUrl : video.maxResThumbnailUrl) else {
                        self.conversionState = .error("Invalid thumbnail URL.")
                        return
                    }

                    self.conversionState = .downloading(progress: 0.1, status: "Saving HD Thumbnail...")
                    let fileName = DownloadManager.sanitizeFileName("\(video.title)_Thumbnail", extension: "jpg")

                    DownloadManager.shared.startDownload(from: thumbUrl, fileName: fileName) { p in
                        Task { @MainActor in
                            self.conversionState = .downloading(progress: p, status: "Downloading: \(Int(p * 100))%")
                        }
                    } completion: { result in
                        Task { @MainActor in
                            switch result {
                            case .success(let fileURL):
                                self.conversionState = .success(fileURL: fileURL, fileName: fileName)
                                self.addHistory(video: video, format: format, fileName: fileName, fileURL: fileURL)
                            case .failure(let err):
                                self.conversionState = .error("Download failed: \(err.localizedDescription)")
                            }
                        }
                    }
                    return
                }

                // 2. Video / Audio Conversion via Loader.to
                // If user requests M4A, we request MP3 (320kbps pristine audio from loader.to)
                // then convert into certified Apple M4A container with AVAudioFile / CoreAudio
                let isM4A = (format.id == "m4a" || format.fileExtension == "m4a")
                let serverFormat = isM4A ? "mp3" : format.id
                self.conversionState = .analyzing("Requesting \(format.label) media stream...")
                let startResult = try await NetworkService.shared.startConversion(
                    format: serverFormat,
                    videoUrl: video.cleanUrl
                )

                var finalDownloadUrl = startResult.downloadUrl
                let conversionId = startResult.id
                let progressUrl = startResult.progressUrl

                // 3. Polling loop if stream is being processed
                if finalDownloadUrl == nil || finalDownloadUrl?.isEmpty == true {
                    var attempts = 0
                    let maxAttempts = 60 // 2 minutes

                    while (finalDownloadUrl == nil || finalDownloadUrl?.isEmpty == true) && attempts < maxAttempts {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                        attempts += 1

                        let progressRes = try await NetworkService.shared.checkProgress(id: conversionId, progressUrl: progressUrl)
                        let percent = progressRes.progressPercent
                        let statusText = progressRes.statusText ?? "Converting stream: \(percent)%"
                        self.conversionState = .converting(progress: percent, status: statusText)

                        if let readyUrl = progressRes.downloadUrl, !readyUrl.isEmpty {
                            finalDownloadUrl = readyUrl
                            break
                        }
                    }
                }

                guard let readyDownloadUrlString = finalDownloadUrl,
                      let readyDownloadUrl = URL(string: readyDownloadUrlString) else {
                    self.conversionState = .error("Conversion timed out. The server is busy, please try another quality.")
                    return
                }

                // 4. Download file to iOS Sandbox / Documents
                let prefix = "[\(format.id.uppercased())]"
                let rawName = "\(prefix) \(video.title)"
                let initialExt = isM4A ? "mp3" : format.fileExtension
                let targetFileName = DownloadManager.sanitizeFileName(rawName, extension: initialExt)

                self.conversionState = .downloading(progress: 0.05, status: "Downloading file...")

                DownloadManager.shared.startDownload(from: readyDownloadUrl, fileName: targetFileName) { progress in
                    Task { @MainActor in
                        self.conversionState = .downloading(progress: progress, status: "Downloading: \(Int(progress * 100))%")
                    }
                } completion: { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let downloadedURL):
                            Task {
                                var finalURL = downloadedURL
                                // If format is M4A, package into certified Apple M4A container
                                if isM4A {
                                    finalURL = await DownloadManager.shared.convertToNativeM4A(sourceURL: downloadedURL)
                                }
                                await MainActor.run {
                                    let finalName = finalURL.lastPathComponent
                                    self.conversionState = .success(fileURL: finalURL, fileName: finalName)
                                    self.addHistory(video: video, format: format, fileName: finalName, fileURL: finalURL)
                                }
                            }
                        case .failure(let err):
                            self.conversionState = .error("Save error: \(err.localizedDescription)")
                        }
                    }
                }

            } catch {
                self.conversionState = .error("Error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - History Management
    private func addHistory(video: VideoItem, format: MediaFormat, fileName: String, fileURL: URL) {
        let item = DownloadHistoryItem(
            videoId: video.videoId,
            title: video.title,
            author: video.author,
            thumbnailUrl: video.thumbnailUrl,
            formatLabel: format.label,
            formatType: format.type,
            fileName: fileName,
            filePath: fileURL.path
        )
        historyItems.insert(item, at: 0)
        saveHistory()
    }

    public func deleteHistoryItem(_ item: DownloadHistoryItem) {
        if let idx = historyItems.firstIndex(where: { $0.id == item.id }) {
            // Delete actual file if exists
            let path = item.filePath
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
            historyItems.remove(at: idx)
            saveHistory()
        }
    }

    public func clearAllHistory() {
        for item in historyItems {
            if FileManager.default.fileExists(atPath: item.filePath) {
                try? FileManager.default.removeItem(atPath: item.filePath)
            }
        }
        historyItems.removeAll()
        saveHistory()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: historyStorageKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyStorageKey),
           let decoded = try? JSONDecoder().decode([DownloadHistoryItem].self, from: data) {
            self.historyItems = decoded
        }
    }
}
