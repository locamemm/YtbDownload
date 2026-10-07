import SwiftUI

public struct VideoCardView: View {
    public let video: VideoItem
    public let onDownload: () -> Void

    public init(video: VideoItem, onDownload: @escaping () -> Void) {
        self.video = video
        self.onDownload = onDownload
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail with Duration Badge
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppTheme.surfaceElevated)
                            .overlay(ProgressView().tint(AppTheme.cyanAccent))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(AppTheme.surfaceElevated)
                            .overlay(
                                Image(systemName: "video.slash")
                                    .foregroundColor(AppTheme.textMuted)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipped()
                .cornerRadius(12)

                // Duration Pill
                if let duration = video.durationText, !duration.isEmpty {
                    Text(duration)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            // Video Info & Download Button
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.author)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.cyanAccent)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let views = video.viewsText, !views.isEmpty {
                                Text(views)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            if video.viewsText != nil && video.publishedText != nil {
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            if let published = video.publishedText, !published.isEmpty {
                                Text(published)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                    }

                    Spacer()

                    // Download Action Button
                    Button(action: onDownload) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.to.line.compact")
                                .font(.system(size: 14, weight: .bold))
                            Text("Tải Về")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.cyanAccent, AppTheme.mintAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.cyanAccent.opacity(0.35), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(12)
        .glassCard(cornerRadius: 16)
    }
}
