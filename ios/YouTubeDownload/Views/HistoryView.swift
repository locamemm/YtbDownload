import SwiftUI
import QuickLook

public struct HistoryView: View {
    @ObservedObject public var viewModel: YouTubeViewModel

    @State private var showClearConfirm: Bool = false
    @State private var shareURL: URL? = nil
    @State private var showShareSheet: Bool = false

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                if viewModel.historyItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(viewModel.historyItems) { item in
                            historyRow(item: item)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteHistoryItem(viewModel.historyItems[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.bottom, 80)
                }
            }
        }
        .alert("Xác Nhận Xóa", isPresented: $showClearConfirm) {
            Button("Xóa Tất Cả", role: .destructive) {
                viewModel.clearAllHistory()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử và các tệp đã tải về không?")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lịch Sử Tải Về")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(viewModel.historyItems.count) tệp đã lưu")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }

            Spacer()

            if !viewModel.historyItems.isEmpty {
                Button(action: {
                    showClearConfirm = true
                }) {
                    Text("Xóa Tất Cả")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.redAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.redAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.textMuted)
            Text("Chưa có tệp nào được tải về")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Hãy tìm kiếm và tải video hoặc nhạc từ tab Khám Phá.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
            Spacer()
        }
    }

    // MARK: - Row View
    private func historyRow(item: DownloadHistoryItem) -> some View {
        let fileExists = FileManager.default.fileExists(atPath: item.filePath)
        let fileURL = URL(fileURLWithPath: item.filePath)

        return HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: item.thumbnailUrl)) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle().fill(AppTheme.surfaceElevated)
                }
            }
            .frame(width: 80, height: 48)
            .cornerRadius(8)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(item.author)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.formatLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            item.formatType == .video ? AppTheme.cyanAccent :
                            item.formatType == .audio ? AppTheme.mintAccent : AppTheme.purpleAccent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(formatDate(item.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 8) {
                if fileExists {
                    Button(action: {
                        self.shareURL = fileURL
                        self.showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.cyanAccent)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.surfaceElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    viewModel.deleteHistoryItem(item)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.redAccent)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
