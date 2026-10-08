import SwiftUI
import Photos
import AVFoundation

public struct DownloadSheetView: View {
    public let video: VideoItem
    @ObservedObject public var viewModel: YouTubeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: FormatType = .video
    @State private var showShareSheet: Bool = false
    @State private var shareURL: URL? = nil
    @State private var photoSavedNotice: String? = nil
    @State private var showDocumentPicker: Bool = false
    @State private var documentTargetURL: URL? = nil
    @State private var documentSavedNotice: String? = nil
    @State private var audioPlayer: AVPlayer? = nil
    @State private var isPlayingAudio: Bool = false

    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Video Info
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                                if let img = phase.image {
                                    img.resizable().aspectRatio(16/9, contentMode: .fill)
                                } else {
                                    Rectangle().fill(AppTheme.surfaceElevated)
                                }
                            }
                            .frame(width: 90, height: 52)
                            .cornerRadius(8)
                            .clipped()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(2)

                                Text(video.author)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.cyanAccent)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)

                        // If In Progress or Finished State
                        switch viewModel.conversionState {
                        case .idle:
                            formatSelectionView

                        case .analyzing(let msg):
                            progressContainer(
                                title: "Đang Khởi Tạo",
                                subtitle: msg,
                                showSpinner: true,
                                progress: nil
                            )

                        case .converting(let percent, let status):
                            progressContainer(
                                title: "Đang Chuyển Đổi Stream",
                                subtitle: status,
                                showSpinner: false,
                                progress: Double(percent) / 100.0,
                                percentLabel: "\(percent)%"
                            )

                        case .downloading(let progress, let status):
                            progressContainer(
                                title: "Đang Tải Về iPhone",
                                subtitle: status,
                                showSpinner: false,
                                progress: progress,
                                percentLabel: "\(Int(progress * 100))%"
                            )

                        case .success(let fileURL, let fileName):
                            successView(fileURL: fileURL, fileName: fileName)

                        case .error(let errorMsg):
                            errorView(message: errorMsg)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Tùy Chọn Định Dạng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.cyanAccent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                if let url = documentTargetURL {
                    DocumentPicker(fileURL: url) { savedURL in
                        self.documentSavedNotice = "✓ Đã lưu thành công vào: \(savedURL.lastPathComponent)"
                    }
                }
            }
            .onDisappear {
                audioPlayer?.pause()
                isPlayingAudio = false
            }
        }
    }

    // MARK: - Format Selection
    private var formatSelectionView: some View {
        VStack(spacing: 16) {
            // Category Tabs
            HStack(spacing: 8) {
                categoryTabButton(title: "Video (MP4)", type: .video, icon: "film")
                categoryTabButton(title: "Audio (M4A/MP3)", type: .audio, icon: "waveform")
                categoryTabButton(title: "Ảnh Bìa", type: .utility, icon: "photo")
            }

            // Quality Options List
            VStack(spacing: 10) {
                ForEach(MediaFormat.allFormats.filter { $0.type == selectedTab }) { format in
                    Button(action: {
                        viewModel.startDownload(format: format)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(format.subLabel)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                Text("Tải")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.cyanAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.cyanAccent.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryTabButton(title: String, type: FormatType, icon: String) -> some View {
        let isSelected = selectedTab == type
        return Button(action: {
            selectedTab = type
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                LinearGradient(colors: [AppTheme.cyanAccent, AppTheme.mintAccent], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [AppTheme.surfaceElevated, AppTheme.surfaceElevated], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Progress Container
    private func progressContainer(title: String, subtitle: String, showSpinner: Bool, progress: Double?, percentLabel: String? = nil) -> some View {
        VStack(spacing: 16) {
            if showSpinner {
                ProgressView()
                    .tint(AppTheme.cyanAccent)
                    .scaleEffect(1.4)
                    .padding(.top, 10)
            }

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            if let p = progress {
                VStack(spacing: 8) {
                    ProgressView(value: p, total: 1.0)
                        .tint(AppTheme.cyanAccent)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .clipShape(Capsule())

                    if let label = percentLabel {
                        Text(label)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.cyanAccent)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard(cornerRadius: 16)
    }

    // MARK: - Success View
    private func successView(fileURL: URL, fileName: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundColor(AppTheme.mintAccent)

            Text("Tải Về Thành Công!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Tệp đã được lưu vào thư mục YouTubeDownloads trong ứng dụng Tệp (Files).")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            if let notice = photoSavedNotice {
                Text(notice)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.mintAccent)
            }

            if let docNotice = documentSavedNotice {
                Text(docNotice)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.cyanAccent)
            }

            VStack(spacing: 10) {
                let ext = fileURL.pathExtension.lowercased()

                // Audio Playback Preview for AAC / M4A / MP3 / WAV
                if ext == "aac" || ext == "m4a" || ext == "mp3" || ext == "wav" {
                    Button(action: {
                        if isPlayingAudio {
                            audioPlayer?.pause()
                            isPlayingAudio = false
                        } else {
                            if audioPlayer == nil {
                                audioPlayer = AVPlayer(url: fileURL)
                            }
                            audioPlayer?.play()
                            isPlayingAudio = true
                        }
                    }) {
                        HStack {
                            Image(systemName: isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 18))
                            Text(isPlayingAudio ? "Tạm Dừng Audio" : "Nghe Thử Ngay (\(ext.uppercased()))")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [AppTheme.mintAccent, AppTheme.cyanAccent], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Choose Save Destination (Document Picker / Files)
                Button(action: {
                    self.documentTargetURL = fileURL
                    self.showDocumentPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Chọn Nơi Lưu Tệp (Lưu Vào Tệp / Files)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [AppTheme.purpleAccent, AppTheme.cyanAccent], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: AppTheme.purpleAccent.opacity(0.35), radius: 6, x: 0, y: 3)
                }

                // Save to Photos if video or image
                if ext == "mp4" || ext == "mov" || ext == "jpg" || ext == "png" {
                    Button(action: {
                        DownloadManager.shared.saveMediaToPhotosAlbum(fileURL: fileURL) { success, err in
                            if success {
                                photoSavedNotice = "✓ Đã lưu vào album Ảnh (Photos)!"
                            } else {
                                photoSavedNotice = "Không thể lưu vào Photos: \(err?.localizedDescription ?? "Từ chối quyền")"
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Lưu Vào Thư Viện Ảnh (Photos)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [AppTheme.mintAccent, AppTheme.cyanAccent], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Share Sheet (AirDrop / Save to Files / Open in VLC)
                Button(action: {
                    self.shareURL = fileURL
                    self.showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Chia Sẻ / Mở Bằng Ứng Dụng Khác")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyanAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Done
                Button("Hoàn Tất") {
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textMuted)
                .padding(.top, 4)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard(cornerRadius: 16)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.redAccent)

            Text("Có Lỗi Xảy Ra")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                viewModel.conversionState = .idle
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Thử Lại")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(AppTheme.cyanAccent)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard(cornerRadius: 16)
    }
}
