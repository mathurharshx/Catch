import Foundation

/// Defines how the capture was initiated.
public enum CaptureSource: String, Codable, CaseIterable, Sendable {
    case text
    case voice
    case widget
    case quickAction
    case deepLink

    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .voice: return "Voice"
        case .widget: return "Widget"
        case .quickAction: return "Quick Action"
        case .deepLink: return "Deep Link"
        }
    }

    public var iconName: String {
        switch self {
        case .text: return "keyboard"
        case .voice: return "mic.fill"
        case .widget: return "square.grid.2x2"
        case .quickAction: return "bolt.fill"
        case .deepLink: return "link"
        }
    }
}
