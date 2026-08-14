import SwiftUI

/// Main container view with bottom navigation and quick capture trigger.
public struct MainTabView: View {
    @Binding public var isPresentingCapture: Bool
    @State private var captureInitialCategory: CaptureType? = nil
    @State private var selectedTab: Int = 0

    public init(isPresentingCapture: Binding<Bool>) {
        self._isPresentingCapture = isPresentingCapture
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView(isPresentingCapture: $isPresentingCapture)
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

            // Floating Quick Capture FAB on non-Home tabs or as permanent shortcut
            if selectedTab != 0 {
                Button(action: {
                    HapticsManager.shared.categorySelected()
                    isPresentingCapture = true
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
        .sheet(isPresented: $isPresentingCapture) {
            QuickCaptureView(initialCategory: captureInitialCategory)
        }
    }
}
