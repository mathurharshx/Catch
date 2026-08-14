import WidgetKit
import SwiftUI

// MARK: - Timeline Entry & Provider

public struct CatchWidgetEntry: TimelineEntry {
    public let date: Date
    public let recentItemCount: Int
    public let lastCaptureText: String?

    public init(date: Date, recentItemCount: Int, lastCaptureText: String?) {
        self.date = date
        self.recentItemCount = recentItemCount
        self.lastCaptureText = lastCaptureText
    }
}

public struct CatchWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> CatchWidgetEntry {
        CatchWidgetEntry(date: Date(), recentItemCount: 4, lastCaptureText: "Buy toothpaste")
    }

    public func getSnapshot(in context: Context, completion: @escaping (CatchWidgetEntry) -> ()) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<CatchWidgetEntry>) -> ()) {
        let entry = loadCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> CatchWidgetEntry {
        let appGroupId = "group.com.catch.app"
        let fileName = "catch_items.json"

        var items: [CaptureItem] = []
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let fileURL = containerURL.appendingPathComponent(fileName)
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([CaptureItem].self, from: data) {
                items = decoded
            }
        }

        return CatchWidgetEntry(
            date: Date(),
            recentItemCount: items.count,
            lastCaptureText: items.first?.content
        )
    }
}

// MARK: - Main Multi-Family Widget

public struct CatchWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    public var entry: CatchWidgetProvider.Entry

    public init(entry: CatchWidgetProvider.Entry) {
        self.entry = entry
    }

    public var body: some View {
        switch widgetFamily {
        // MARK: - Lock Screen Circular Accessory
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "catch://capture")!)

        // MARK: - Lock Screen Rectangular Accessory
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Catch")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(entry.lastCaptureText ?? "Tap to capture...")
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
            }
            .widgetURL(URL(string: "catch://capture")!)

        // MARK: - Lock Screen Inline Accessory
        case .accessoryInline:
            Label("Capture thought", systemImage: "plus")
                .widgetURL(URL(string: "catch://capture")!)

        // MARK: - Home Screen Small Widget
        case .systemSmall:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.38, green: 0.45, blue: 0.98))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(entry.recentItemCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Catch")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(entry.lastCaptureText ?? "Tap to capture instantly")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .widgetURL(URL(string: "catch://capture")!)

        // MARK: - Home Screen Medium Widget
        case .systemMedium:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("QUICK CAPTURE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.recentItemCount) captured")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    widgetCategoryButton(title: "Note", icon: "doc.text", color: Color(red: 0.38, green: 0.45, blue: 0.98), url: "catch://capture?type=note")
                    widgetCategoryButton(title: "Idea", icon: "lightbulb", color: Color(red: 0.96, green: 0.65, blue: 0.14), url: "catch://capture?type=idea")
                    widgetCategoryButton(title: "Task", icon: "checkmark.circle", color: Color(red: 0.20, green: 0.78, blue: 0.55), url: "catch://capture?type=task")
                    widgetCategoryButton(title: "Expense", icon: "creditcard", color: Color(red: 0.95, green: 0.33, blue: 0.42), url: "catch://capture?type=expense")
                }
            }
            .padding(14)

        default:
            Text("Catch")
                .widgetURL(URL(string: "catch://capture")!)
        }
    }

    private func widgetCategoryButton(title: String, icon: String, color: Color, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

public struct CatchWidget: Widget {
    public let kind: String = "CatchWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatchWidgetProvider()) { entry in
            CatchWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Capture")
        .description("Save thoughts, ideas, tasks, and expenses instantly.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Dedicated Category Lock Screen Widgets

public struct TaskLockScreenWidget: Widget {
    public let kind: String = "TaskLockScreenWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatchWidgetProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "catch://capture?type=task")!)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Capture Task")
        .description("1-tap shortcut to capture a task.")
        .supportedFamilies([.accessoryCircular])
    }
}

public struct ExpenseLockScreenWidget: Widget {
    public let kind: String = "ExpenseLockScreenWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatchWidgetProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "catch://capture?type=expense")!)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Capture Expense")
        .description("1-tap shortcut to log an expense.")
        .supportedFamilies([.accessoryCircular])
    }
}

public struct IdeaLockScreenWidget: Widget {
    public let kind: String = "IdeaLockScreenWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatchWidgetProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "catch://capture?type=idea")!)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Capture Idea")
        .description("1-tap shortcut to capture a new idea.")
        .supportedFamilies([.accessoryCircular])
    }
}

public struct NoteLockScreenWidget: Widget {
    public let kind: String = "NoteLockScreenWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatchWidgetProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "catch://capture?type=note")!)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Capture Note")
        .description("1-tap shortcut to capture a note.")
        .supportedFamilies([.accessoryCircular])
    }
}
