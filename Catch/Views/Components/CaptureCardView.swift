import SwiftUI

/// Elegant, minimalist card for a captured item in lists and streams.
public struct CaptureCardView: View {
    public let item: CaptureItem
    public var searchQuery: String = ""
    public var onToggleTask: (() -> Void)?
    public var onTap: (() -> Void)?

    public init(
        item: CaptureItem,
        searchQuery: String = "",
        onToggleTask: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.item = item
        self.searchQuery = searchQuery
        self.onToggleTask = onToggleTask
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Task Animated Checkbox or Category Indicator Dot
                if item.type == .task {
                    TaskCheckboxView(isCompleted: item.isCompleted) {
                        onToggleTask?()
                    }
                    .padding(.top, 1)
                } else {
                    Circle()
                        .fill(item.type.tintColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 7)
                }

                // Main Content & Metadata
                VStack(alignment: .leading, spacing: 6) {
                    // Content text with search term highlighting
                    HighlightedText(
                        text: item.content,
                        query: searchQuery,
                        isStrikethrough: item.isCompleted,
                        textColor: item.isCompleted ? Theme.secondaryText : Theme.primaryText,
                        highlightColor: item.type.tintColor
                    )
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                    // Footer row: Category, Source, Expense amount, Reminder, Timestamp
                    HStack(spacing: 8) {
                        CategoryBadge(type: item.type, isSelected: false, showText: true)

                        if let formattedAmount = item.formattedAmount {
                            Text(formattedAmount)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accentExpense)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.accentExpense.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        if item.source == .voice {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.secondaryText)
                        } else if item.source == .widget {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.secondaryText)
                        }

                        if item.reminderDate != nil {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.accentWarm)
                        }

                        Spacer()

                        Text(item.timeFormatted)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Theme.tertiaryText)
                    }
                }
            }
            .padding(14)
            .catchCard()
        }
        .buttonStyle(.plain)
    }
}
