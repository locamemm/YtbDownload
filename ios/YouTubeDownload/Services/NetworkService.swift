import Foundation

public final class NetworkService {
    public static let shared = NetworkService()

    private let userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

    private let invidiousInstances: [String] = [
        "https://inv.vern.cc",
        "https://invidious.asir.dev",
        "https://invidious.fdn.fr",
        "https://yt.drgnz.club"
    ]

    private init() {}

    // MARK: - Direct Video ID Extractor
    public func extractVideoId(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count == 11 && !trimmed.contains("/") && !trimmed.contains("?") {
            return trimmed
        }
        let patterns = [
            #"(?:v=|\/v\/|youtu\.be\/|embed\/|\/live\/|\/shorts\/)([a-zA-Z0-9_-]{11})"#,
            #"([a-zA-Z0-9_-]{11})"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
                if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: trimmed) {
                    return String(trimmed[range])
                }
            }
        }
        return nil
    }

    // MARK: - Search Videos
    public func searchVideos(query: String) async throws -> [VideoItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }

        // If user pasted a direct YouTube URL or ID, provide immediate item
        if let directId = extractVideoId(from: cleanQuery), cleanQuery.contains("youtu") || cleanQuery.count == 11 {
            let directItem = VideoItem(
                videoId: directId,
                title: "Direct Video Link (\(directId))",
                author: "YouTube",
                thumbnailUrl: "https://i.ytimg.com/vi/\(directId)/hqdefault.jpg",
                durationText: "Video"
            )
            // Attempt to enrich or return
            if let innerTubeResults = try? await searchInnerTube(query: directId), !innerTubeResults.isEmpty {
                return innerTubeResults
            }
            return [directItem]
        }

        // 1. Try Primary: Official YouTube InnerTube API
        do {
            let innerTubeResults = try await searchInnerTube(query: cleanQuery)
            if !innerTubeResults.isEmpty {
                return innerTubeResults
            }
        } catch {
            // Fallback to secondary
        }

        // 2. Try Invidious Public Instances
        for instance in invidiousInstances {
            if let invidiousResults = try? await searchInvidious(instanceUrl: instance, query: cleanQuery), !invidiousResults.isEmpty {
                return invidiousResults
            }
        }

        throw NSError(domain: "NetworkService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No videos found. Please check your query or connection."])
    }

    // MARK: - InnerTube Search API
    private func searchInnerTube(query: String) async throws -> [VideoItem] {
        guard let url = URL(string: "https://www.youtube.com/youtubei/v1/search") else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "context": [
                "client": [
                    "clientName": "WEB",
                    "clientVersion": "2.20240101.00.00",
                    "hl": "en",
                    "gl": "US"
                ]
            ],
            "query": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        return parseInnerTubeResponse(json: json)
    }

    private func parseInnerTubeResponse(json: [String: Any]) -> [VideoItem] {
        var items: [VideoItem] = []
        guard let contents = json["contents"] as? [String: Any],
              let twoCol = contents["twoColumnSearchResultsRenderer"] as? [String: Any],
              let primary = twoCol["primaryContents"] as? [String: Any],
              let sectionList = primary["sectionListRenderer"] as? [String: Any],
              let sectionContents = sectionList["contents"] as? [[String: Any]] else {
            return []
        }

        for section in sectionContents {
            guard let itemSection = section["itemSectionRenderer"] as? [String: Any],
                  let sectionItems = itemSection["contents"] as? [[String: Any]] else { continue }

            for item in sectionItems {
                guard let vr = item["videoRenderer"] as? [String: Any],
                      let videoId = vr["videoId"] as? String else { continue }

                // Title
                var title = "Untitled Video"
                if let titleObj = vr["title"] as? [String: Any],
                   let runs = titleObj["runs"] as? [[String: Any]] {
                    title = runs.compactMap { $0["text"] as? String }.joined()
                }

                // Author
                var author = "YouTube Creator"
                if let ownerObj = vr["ownerText"] as? [String: Any],
                   let runs = ownerObj["runs"] as? [[String: Any]] {
                    author = runs.compactMap { $0["text"] as? String }.joined()
                }

                // Duration
                var durationText: String? = nil
                if let lenObj = vr["lengthText"] as? [String: Any],
                   let simple = lenObj["simpleText"] as? String {
                    durationText = simple
                }

                // Views
                var viewsText: String? = nil
                if let viewsObj = vr["shortViewCountText"] as? [String: Any],
                   let simple = viewsObj["simpleText"] as? String {
                    viewsText = simple
                }

                // Published
                var publishedText: String? = nil
                if let pubObj = vr["publishedTimeText"] as? [String: Any],
                   let simple = pubObj["simpleText"] as? String {
                    publishedText = simple
                }

                // Thumbnail
                var thumbUrl = "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"
                if let thumbObj = vr["thumbnail"] as? [String: Any],
                   let thumbs = thumbObj["thumbnails"] as? [[String: Any]],
                   let lastThumb = thumbs.last,
                   let u = lastThumb["url"] as? String {
                    thumbUrl = u
                }

                items.append(VideoItem(
                    videoId: videoId,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                    lengthSeconds: parseDuration(durationText ?? ""),
                    thumbnailUrl: thumbUrl,
                    publishedText: publishedText,
                    durationText: durationText,
                    viewsText: viewsText
                ))
            }
        }

        var uniqueDict: [String: VideoItem] = [:]
        for item in items {
            if uniqueDict[item.videoId] == nil {
                uniqueDict[item.videoId] = item
            }
        }
        return Array(uniqueDict.values)
    }

    private func parseDuration(_ text: String) -> Int64 {
        let parts = text.split(separator: ":").compactMap { Int64($0) }
        switch parts.count {
        case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
        case 2: return parts[0] * 60 + parts[1]
        case 1: return parts[0]
        default: return 0
        }
    }

    // MARK: - Invidious Search
    private func searchInvidious(instanceUrl: String, query: String) async throws -> [VideoItem] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(instanceUrl)/api/v1/search?q=\(encoded)&type=video") else { return [] }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }

        return array.compactMap { dict -> VideoItem? in
            guard let videoId = dict["videoId"] as? String,
                  let title = dict["title"] as? String else { return nil }
            let author = dict["author"] as? String ?? "YouTube Creator"
            let lengthSec = dict["lengthSeconds"] as? Int64 ?? 0
            let durationText: String? = lengthSec > 0 ? "\(lengthSec / 60):\(String(format: "%02d", lengthSec % 60))" : nil

            return VideoItem(
                videoId: videoId,
                title: title,
                author: author,
                lengthSeconds: lengthSec,
                thumbnailUrl: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg",
                durationText: durationText
            )
        }
    }

    // MARK: - Loader.to Conversion Engine
    public struct LoaderStartResult {
        public let id: String?
        public let downloadUrl: String?
        public let progressUrl: String?
        public let errorText: String?
    }

    public func startConversion(format: String, videoUrl: String) async throws -> LoaderStartResult {
        guard let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://loader.to/ajax/download.php?button=1&start=1&end=1&format=\(format)&url=\(encodedUrl)") else {
            throw NSError(domain: "LoaderTo", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request URL."])
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://loader.to", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "LoaderTo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server response error."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "LoaderTo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot parse response."])
        }

        let id = json["id"] as? String
        var downloadUrl = json["download_url"] as? String
        if downloadUrl == nil || downloadUrl == "null" || downloadUrl?.isEmpty == true {
            downloadUrl = json["url"] as? String
        }
        let progressUrl = json["progress_url"] as? String
        let errorText = json["text"] as? String

        return LoaderStartResult(id: id, downloadUrl: downloadUrl, progressUrl: progressUrl, errorText: errorText)
    }

    public struct LoaderProgressResult {
        public let progressPercent: Int
        public let downloadUrl: String?
        public let statusText: String?
    }

    public func checkProgress(id: String?, progressUrl: String?) async throws -> LoaderProgressResult {
        let endpointString: String
        if let progressUrl = progressUrl, !progressUrl.isEmpty {
            endpointString = progressUrl
        } else if let id = id, !id.isEmpty {
            endpointString = "https://loader.to/ajax/progress.php?id=\(id)"
        } else {
            throw NSError(domain: "LoaderTo", code: 400, userInfo: [NSLocalizedDescriptionKey: "No conversion tracking ID."])
        }

        guard let url = URL(string: endpointString) else {
            throw NSError(domain: "LoaderTo", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid progress URL."])
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://loader.to", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "LoaderTo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Progress server error."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return LoaderProgressResult(progressPercent: 0, downloadUrl: nil, statusText: "Processing...")
        }

        let rawProgress = (json["progress"] as? NSNumber)?.intValue ?? 0
        let percent = min(100, max(0, rawProgress / 10))

        var downloadUrl = json["download_url"] as? String
        if downloadUrl == nil || downloadUrl == "null" || downloadUrl?.isEmpty == true {
            downloadUrl = json["url"] as? String
        }
        let statusText = json["text"] as? String

        return LoaderProgressResult(progressPercent: percent, downloadUrl: downloadUrl, statusText: statusText)
    }
}
