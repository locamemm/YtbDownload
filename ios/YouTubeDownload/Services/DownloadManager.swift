import Foundation
import Photos
import UIKit
import AVFoundation

public final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()

    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var progressCallback: ((Double) -> Void)?
    private var completionCallback: ((Result<URL, Error>) -> Void)?
    private var destinationFileName: String = "media.mp4"

    override private init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    // MARK: - Safe Directory
    public var downloadsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("YouTubeDownloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }

    public static func sanitizeFileName(_ rawName: String, extension ext: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        var clean = rawName.components(separatedBy: invalidCharacters).joined(separator: "_")
        clean = clean.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count > 60 {
            clean = String(clean.prefix(60))
        }
        if clean.isEmpty {
            clean = "YouTube_Media"
        }
        let cleanExt = ext.replacingOccurrences(of: ".", with: "")
        return "\(clean).\(cleanExt)"
    }

    // MARK: - Download File
    public func startDownload(
        from url: URL,
        fileName: String,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.destinationFileName = fileName
        self.progressCallback = progress
        self.completionCallback = completion

        self.downloadTask?.cancel()
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://loader.to/", forHTTPHeaderField: "Referer")
        self.downloadTask = session.downloadTask(with: request)
        self.downloadTask?.resume()
    }

    public func cancelCurrentDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        progressCallback = nil
        completionCallback = nil
    }

    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let frac = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            let clamped = min(1.0, max(0.0, frac))
            DispatchQueue.main.async { [weak self] in
                self?.progressCallback?(clamped)
            }
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 1. Verify HTTP Response Status
        if let http = downloadTask.response as? HTTPURLResponse, http.statusCode != 200 {
            let err = NSError(domain: "DownloadManager", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Máy chủ trả về lỗi HTTP \(http.statusCode). Vui lòng thử lại chất lượng khác."
            ])
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(.failure(err))
            }
            return
        }

        // 2. Verify Downloaded File Size (prevent saving corrupt HTML/tiny fragments)
        let attr = try? FileManager.default.attributesOfItem(atPath: location.path)
        let fileSize = (attr?[.size] as? Int64) ?? 0
        if fileSize < 20480 { // Under 20 KB
            let err = NSError(domain: "DownloadManager", code: 422, userInfo: [
                NSLocalizedDescriptionKey: "Tệp tải về không hoàn chỉnh hoặc quá nhỏ (\(fileSize) bytes). Vui lòng thử lại."
            ])
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(.failure(err))
            }
            return
        }

        // 3. Move File to Final Destination
        let destURL = downloadsDirectory.appendingPathComponent(destinationFileName)

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: location, to: destURL)
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(.success(destURL))
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(.failure(error))
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(.failure(error))
            }
        }
    }

    // MARK: - Native M4A Remuxing / Transcoding (Apple Certified)
    public func convertToNativeM4A(sourceURL: URL) async -> URL {
        let targetM4A = sourceURL.deletingPathExtension().appendingPathExtension("m4a")
        let tempTarget = downloadsDirectory.appendingPathComponent("remux_\(UUID().uuidString).m4a")

        // 1. Primary: CoreAudio AVAudioFile PCM transcoding to pristine AAC M4A
        do {
            let inputFile = try AVAudioFile(forReading: sourceURL)
            let inFormat = inputFile.processingFormat

            let outSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: inFormat.sampleRate,
                AVNumberOfChannelsKey: min(2, inFormat.channelCount),
                AVEncoderBitRateKey: 256000
            ]

            let outputFile = try AVAudioFile(
                forWriting: tempTarget,
                settings: outSettings,
                commonFormat: inFormat.commonFormat,
                interleaved: inFormat.isInterleaved
            )

            if let buffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: 8192) {
                while inputFile.framePosition < inputFile.length {
                    let framesToRead = AVAudioFrameCount(min(8192, inputFile.length - inputFile.framePosition))
                    try inputFile.read(into: buffer, frameCount: framesToRead)
                    try outputFile.write(from: buffer)
                }
            }

            let attr = try? FileManager.default.attributesOfItem(atPath: tempTarget.path)
            let size = (attr?[.size] as? Int64) ?? 0
            if size > 20480 {
                if FileManager.default.fileExists(atPath: targetM4A.path) {
                    try? FileManager.default.removeItem(at: targetM4A)
                }
                try FileManager.default.moveItem(at: tempTarget, to: targetM4A)
                if sourceURL.path != targetM4A.path && FileManager.default.fileExists(atPath: sourceURL.path) {
                    try? FileManager.default.removeItem(at: sourceURL)
                }
                return targetM4A
            }
        } catch {
            try? FileManager.default.removeItem(at: tempTarget)
        }

        // 2. Secondary fallback: AVAssetExportSession
        let asset = AVURLAsset(url: sourceURL)
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
            exportSession.outputURL = tempTarget
            exportSession.outputFileType = .m4a
            await exportSession.export()

            if exportSession.status == .completed && FileManager.default.fileExists(atPath: tempTarget.path) {
                let attr = try? FileManager.default.attributesOfItem(atPath: tempTarget.path)
                let size = (attr?[.size] as? Int64) ?? 0
                if size > 20480 {
                    if FileManager.default.fileExists(atPath: targetM4A.path) {
                        try? FileManager.default.removeItem(at: targetM4A)
                    }
                    try? FileManager.default.moveItem(at: tempTarget, to: targetM4A)
                    if sourceURL.path != targetM4A.path && FileManager.default.fileExists(atPath: sourceURL.path) {
                        try? FileManager.default.removeItem(at: sourceURL)
                    }
                    return targetM4A
                }
            }
            try? FileManager.default.removeItem(at: tempTarget)
        }

        return sourceURL
    }

    // MARK: - Save to Photos Library
    public func saveMediaToPhotosAlbum(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let ext = fileURL.pathExtension.lowercased()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "Photos", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                if ext == "mp4" || ext == "mov" {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                } else if ext == "jpg" || ext == "jpeg" || ext == "png" {
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                }
            }) { success, err in
                DispatchQueue.main.async {
                    completion(success, err)
                }
            }
        }
    }
}
