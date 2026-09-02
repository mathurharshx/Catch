import SwiftUI

/// Main container view with bottom navigation and quick capture trigger.
public struct MainTabView: View {
    @Binding public var captureSheetConfig: CaptureSheetConfig?
    @State private var selectedTab: Int = 0

    public init(captureSheetConfig: Binding<CaptureSheetConfig?>) {
        self._captureSheetConfig = captureSheetConfig
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView(captureSheetConfig: $captureSheetConfig)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(Theme.brandTint)

            // Floating Quick Capture FAB on non-Home tabs
            if selectedTab != 0 {
                Button(action: {
                    HapticsManager.shared.categorySelected()
                    captureSheetConfig = CaptureSheetConfig()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(Theme.brandTint)
                        .clipShape(Circle())
                        .shadow(color: Theme.brandTint.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 64)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(item: $captureSheetConfig) { config in
            QuickCaptureView(initialCategory: config.category, initialSource: config.source, initialText: config.initialText)
        }
        .onOpenURL { url in
            let host = url.host?.lowercased() ?? ""
            let path = url.path.lowercased()
            if host == "history" || path.contains("history") {
                selectedTab = 1
            } else if host == "settings" || path.contains("settings") {
                selectedTab = 2
            } else if host == "home" {
                selectedTab = 0
            }
        }
    }
}
