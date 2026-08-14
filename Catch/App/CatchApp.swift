import SwiftUI

@main
struct CatchApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var isPresentingCapture: Bool = false
    @State private var initialCategoryForCapture: CaptureType? = nil

    init() {
        // Configure standard appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(isPresentingCapture: $isPresentingCapture)
                .onAppear {
                    if userSettings.openCaptureOnColdLaunch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPresentingCapture = true
                        }
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "catch" else { return }

        // Host could be "capture" e.g. catch://capture?type=task
        if url.host == "capture" || url.path.contains("capture") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let typeParam = components.queryItems?.first(where: { $0.name == "type" })?.value,
               let type = CaptureType(rawValue: typeParam) {
                initialCategoryForCapture = type
            } else {
                initialCategoryForCapture = nil
            }
            isPresentingCapture = true
        }
    }
}
