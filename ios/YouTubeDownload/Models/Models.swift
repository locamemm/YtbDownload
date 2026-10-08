import Foundation

// MARK: - Video Item Model
public struct VideoItem: Identifiable, Hashable, Codable {
    public var id: String { videoId }
    public let videoId: String
    public let title: String
    public let author: String
    public let lengthSeconds: Int64
    public let thumbnailUrl: String
    public let publishedText: String?
    public let durationText: String?
    public let viewsText: String?

    public var cleanUrl: String {
        return "https://www.youtube.com/watch?v=\(videoId)"
    }

    public var maxResThumbnailUrl: String {
        return "https://i.ytimg.com/vi/\(videoId)/maxresdefault.jpg"
    }

    public init(
        videoId: String,
        title: String,
        author: String,
        lengthSeconds: Int64 = 0,
        thumbnailUrl: String,
        publishedText: String? = nil,
        durationText: String? = nil,
        viewsText: String? = nil
    ) {
        self.videoId = videoId
        self.title = title
        self.author = author
        self.lengthSeconds = lengthSeconds
        self.thumbnailUrl = thumbnailUrl
        self.publishedText = publishedText
        self.durationText = durationText
        self.viewsText = viewsText
    }
}

// MARK: - Format Category
public enum FormatType: String, Codable, CaseIterable {
    case video = "VIDEO"
    case audio = "AUDIO"
    case utility = "UTILITY"
}

// MARK: - Media Format Definition
public struct MediaFormat: Identifiable, Hashable {
    public let id: String
    public let label: String
    public let subLabel: String
    public let type: FormatType
    public let fileExtension: String
    public let mimeType: String

    // Video Formats
    public static let video1080 = MediaFormat(
        id: "1080",
        label: "1080p FHD",
        subLabel: "MP4 • High Definition",
        type: .video,
        fileExtension: "mp4",
        mimeType: "video/mp4"
    )
    public static let video720 = MediaFormat(
        id: "720",
        label: "720p HD",
        subLabel: "MP4 • Standard HD",
        type: .video,
        fileExtension: "mp4",
        mimeType: "video/mp4"
    )
    public static let video480 = MediaFormat(
        id: "480",
        label: "480p",
        subLabel: "MP4 • Medium Quality",
        type: .video,
        fileExtension: "mp4",
        mimeType: "video/mp4"
    )
    public static let video360 = MediaFormat(
        id: "360",
        label: "360p",
        subLabel: "MP4 • Data Saver",
        type: .video,
        fileExtension: "mp4",
        mimeType: "video/mp4"
    )

    // Audio Formats
    public static let audioMP3 = MediaFormat(
        id: "mp3",
        label: "MP3 Audio",
        subLabel: "320 kbps • High Quality",
        type: .audio,
        fileExtension: "mp3",
        mimeType: "audio/mpeg"
    )
    public static let audioM4A = MediaFormat(
        id: "m4a",
        label: "M4A Audio",
        subLabel: "Apple AAC • 256 kbps M4A",
        type: .audio,
        fileExtension: "m4a",
        mimeType: "audio/mp4"
    )
    public static let audioWAV = MediaFormat(
        id: "wav",
        label: "WAV Audio",
        subLabel: "Lossless Master",
        type: .audio,
        fileExtension: "wav",
        mimeType: "audio/wav"
    )

    // Utilities
    public static let thumbnailHD = MediaFormat(
        id: "thumbnail",
        label: "HD Thumbnail",
        subLabel: "MaxRes 1080p JPG",
        type: .utility,
        fileExtension: "jpg",
        mimeType: "image/jpeg"
    )

    public static let allFormats: [MediaFormat] = [
        .video1080, .video720, .video480, .video360,
        .audioMP3, .audioM4A, .audioWAV,
        .thumbnailHD
    ]
}

// MARK: - Download History Item
public struct DownloadHistoryItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let videoId: String
    public let title: String
    public let author: String
    public let thumbnailUrl: String
    public let formatLabel: String
    public let formatType: FormatType
    public let fileName: String
    public let filePath: String
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        videoId: String,
        title: String,
        author: String,
        thumbnailUrl: String,
        formatLabel: String,
        formatType: FormatType,
        fileName: String,
        filePath: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.videoId = videoId
        self.title = title
        self.author = author
        self.thumbnailUrl = thumbnailUrl
        self.formatLabel = formatLabel
        self.formatType = formatType
        self.fileName = fileName
        self.filePath = filePath
        self.timestamp = timestamp
    }
}

// MARK: - Conversion UI State
public enum ConversionState: Equatable {
    case idle
    case analyzing(String)
    case converting(progress: Int, status: String)
    case downloading(progress: Double, status: String)
    case success(fileURL: URL, fileName: String)
    case error(String)
}
