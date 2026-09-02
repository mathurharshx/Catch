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
                VStack(alignment: .leading, spacing: 8) {
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

                    // Subtask Checklist Items with Live Progress Track (if present)
                    if let checklist = item.checklistItems, !checklist.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Mini Animated Progress Track
                            let total = item.totalChecklistCount
                            let completed = item.completedChecklistCount
                            let progress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

                            HStack(spacing: 8) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Theme.secondaryBackground)
                                            .frame(height: 5)

                                        Capsule()
                                            .fill(completed == total ? Theme.accentSuccess : Theme.brandTint)
                                            .frame(width: max(geo.size.width * progress, 0), height: 5)
                                            .animation(.spring(response: 0.38, dampingFraction: 0.75), value: progress)
                                    }
                                }
                                .frame(height: 5)

                                Text("\(completed)/\(total)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(completed == total ? Theme.accentSuccess : Theme.secondaryText)
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 2)

                            // Subtask items list
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(checklist) { checkItem in
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            HapticsManager.shared.light()
                                            DataStore.shared.toggleChecklistItem(itemId: item.id, checklistItemId: checkItem.id)
                                        }) {
                                            Image(systemName: checkItem.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(checkItem.isCompleted ? Theme.accentSuccess : Theme.secondaryText.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)

                                        Text(checkItem.title)
                                            .font(.system(size: 13, weight: .regular))
                                            .strikethrough(checkItem.isCompleted)
                                            .foregroundColor(checkItem.isCompleted ? Theme.secondaryText : Theme.primaryText)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(Theme.secondaryBackground.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    // Footer row: Category, Checklist progress, Source, Expense amount, Reminder, Timestamp
                    HStack(spacing: 8) {
                        CategoryBadge(type: item.type, isSelected: false, showText: true)

                        if item.totalChecklistCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 10))
                                Text("\(item.completedChecklistCount)/\(item.totalChecklistCount)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(item.completedChecklistCount == item.totalChecklistCount ? Theme.accentSuccess : Theme.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.secondaryBackground)
                            .clipShape(Capsule())
                        }

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
