import SwiftUI

@main
struct CatchApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var captureSheetConfig: CaptureSheetConfig? = nil

    @State private var showSplash: Bool = true

    init() {
        // Configure standard appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView(captureSheetConfig: $captureSheetConfig)

                if showSplash {
                    LaunchSplashView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                        if userSettings.openCaptureOnColdLaunch {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if captureSheetConfig == nil {
                                    captureSheetConfig = CaptureSheetConfig()
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .onOpenURL { url in
                showSplash = false
                handleDeepLink(url: url)
            }
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "catch" else { return }

        var selectedType: CaptureType? = nil
        var initialText: String? = nil

        // Support catch://capture?type=task or catch://task or catch://expense etc.
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        if host == "capture" || path.contains("capture") || url.absoluteString.starts(with: "catch://capture") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                if let typeParam = components.queryItems?.first(where: { $0.name == "type" || $0.name == "category" })?.value,
                   let type = CaptureType(rawValue: typeParam.lowercased()) {
                    selectedType = type
                }
                if let textParam = components.queryItems?.first(where: { $0.name == "text" || $0.name == "content" })?.value {
                    initialText = textParam
                }
            }
        } else if let directType = CaptureType(rawValue: host) {
            // Direct scheme shortcut e.g. catch://task or catch://expense
            selectedType = directType
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let textParam = components.queryItems?.first(where: { $0.name == "text" || $0.name == "content" })?.value {
                initialText = textParam
            }
        }

        // Set config with fresh UUID to trigger SwiftUI sheet presentation cleanly
        captureSheetConfig = CaptureSheetConfig(category: selectedType, initialText: initialText)
    }
}
