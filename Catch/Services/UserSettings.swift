import SwiftUI

/// User preferences for Catch.
@MainActor
public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    private let defaults: UserDefaults

    @Published public var defaultCategory: CaptureType {
        didSet {
            defaults.set(defaultCategory.rawValue, forKey: "defaultCategory")
        }
    }

    @Published public var defaultCurrency: String {
        didSet {
            defaults.set(defaultCurrency, forKey: "defaultCurrency")
        }
    }

    @Published public var autoFocusKeyboard: Bool {
        didSet {
            defaults.set(autoFocusKeyboard, forKey: "autoFocusKeyboard")
        }
    }

    @Published public var enableHaptics: Bool {
        didSet {
            defaults.set(enableHaptics, forKey: "enableHaptics")
        }
    }

    @Published public var openCaptureOnColdLaunch: Bool {
        didSet {
            defaults.set(openCaptureOnColdLaunch, forKey: "openCaptureOnColdLaunch")
        }
    }

    private init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults

        let savedCat = defaults.string(forKey: "defaultCategory") ?? CaptureType.note.rawValue
        self.defaultCategory = CaptureType(rawValue: savedCat) ?? .note

        self.defaultCurrency = defaults.string(forKey: "defaultCurrency") ?? "₹"
        self.autoFocusKeyboard = defaults.object(forKey: "autoFocusKeyboard") != nil ? defaults.bool(forKey: "autoFocusKeyboard") : true
        self.enableHaptics = defaults.object(forKey: "enableHaptics") != nil ? defaults.bool(forKey: "enableHaptics") : true
        self.openCaptureOnColdLaunch = defaults.object(forKey: "openCaptureOnColdLaunch") != nil ? defaults.bool(forKey: "openCaptureOnColdLaunch") : false
    }
}
