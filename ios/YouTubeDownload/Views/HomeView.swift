import SwiftUI
import UIKit

public struct HomeView: View {
    @ObservedObject public var viewModel: YouTubeViewModel

    private let quickTags = [
        "Trending", "Nhạc Trẻ 2024", "Remix Bass Cực Căng", "Lofi Chill",
        "Rap Việt", "Podcast", "Shorts Hay", "4K HDR Nature"
    ]

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Header
                headerView

                // Main Scroll Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Search Bar & Paste Button
                        searchBarSection

                        // Quick Tags
                        quickTagsSection

                        // Search Results or Loading
                        if viewModel.isSearching {
                            loadingSection
                        } else if let error = viewModel.searchError {
                            errorSection(error: error)
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 90)
                }
                .refreshable {
                    viewModel.search()
                }
            }
        }
        .sheet(isPresented: $viewModel.showDownloadSheet) {
            if let video = viewModel.selectedVideo {
                DownloadSheetView(video: video, viewModel: viewModel)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 34, height: 34)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("YouTube Downloader")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("iPhone Edition • High Speed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.cyanAccent)
                }
            }

            Spacer()

            // Status Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(AppTheme.mintAccent)
                    .frame(width: 6, height: 6)
                Text("Ready")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.mintAccent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.surfaceElevated)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Search Bar & Quick Paste
    private var searchBarSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.cyanAccent)
                    .font(.system(size: 16))

                TextField("Tìm kiếm hoặc dán link YouTube...", text: $viewModel.searchQuery)
                    .foregroundColor(AppTheme.textPrimary)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        viewModel.search()
                    }

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                            .font(.system(size: 16))
                    }
                }

                // Paste from clipboard button
                Button(action: {
                    if let string = UIPasteboard.general.string, !string.isEmpty {
                        viewModel.searchQuery = string
                        viewModel.search()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 12))
                        Text("Dán")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.cyanAccent)
                    .clipShape(Capsule())
                }
            }
            .padding(12)
            .glassCard(cornerRadius: 14)

            // Submit Button
            Button(action: {
                viewModel.search()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("Tìm Kiếm & Phân Tích Link")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: AppTheme.cyanAccent.opacity(0.3), radius: 8, x: 0, y: 3)
            }
        }
    }

    // MARK: - Quick Tags
    private var quickTagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickTags, id: \.self) { tag in
                    Button(action: {
                        viewModel.search(keyword: tag)
                    }) {
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.searchQuery == tag ? .black : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                viewModel.searchQuery == tag ?
                                LinearGradient(colors: [AppTheme.cyanAccent, AppTheme.mintAccent], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [AppTheme.surfaceCard, AppTheme.surfaceCard], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.cardBorderGradient, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.cyanAccent)
                .scaleEffect(1.3)
            Text("Đang tải dữ liệu từ YouTube...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error Section
    private func errorSection(error: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.redAccent)
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Thử lại") {
                viewModel.search()
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppTheme.cyanAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Results Section
    private var resultsSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.searchResults) { video in
                VideoCardView(video: video) {
                    viewModel.selectVideo(video)
                }
            }
        }
    }
}
