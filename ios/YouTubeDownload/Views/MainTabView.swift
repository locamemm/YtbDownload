import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = YouTubeViewModel()
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: viewModel)
                    .tag(0)

                HistoryView(viewModel: viewModel)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            // Custom Floating Bottom Navigation Bar
            floatingNavBar
        }
        .preferredColorScheme(.dark)
    }

    private var floatingNavBar: some View {
        HStack(spacing: 40) {
            navButton(title: "Khám Phá", icon: "sparkle.magnifyingglass", tag: 0)
            navButton(title: "Lịch Sử", icon: "arrow.down.circle.fill", tag: 1, badgeCount: viewModel.historyItems.count)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceElevated.opacity(0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.cardBorderGradient, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        .padding(.bottom, 20)
    }

    private func navButton(title: String, icon: String, tag: Int, badgeCount: Int = 0) -> some View {
        let isSelected = selectedTab == tag
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? AppTheme.cyanAccent : AppTheme.textMuted)

                    if badgeCount > 0 {
                        Text("\(min(badgeCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(AppTheme.mintAccent)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -6)
                    }
                }

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? AppTheme.cyanAccent : AppTheme.textMuted)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
        }
    }
}
