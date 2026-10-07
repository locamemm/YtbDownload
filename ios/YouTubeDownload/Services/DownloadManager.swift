import Foundation
import Photos
import UIKit

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
            progressCallback?(min(1.0, max(0.0, frac)))
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destURL = downloadsDirectory.appendingPathComponent(destinationFileName)

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: location, to: destURL)
            completionCallback?(.success(destURL))
        } catch {
            completionCallback?(.failure(error))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionCallback?(.failure(error))
        }
    }

    // MARK: - Save to Photos Library
    public func saveMediaToPhotosAlbum(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let ext = fileURL.pathExtension.lowercased()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, NSError(domain: "Photos", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
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
