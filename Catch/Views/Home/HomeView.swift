import SwiftUI

/// The minimalist Home screen showing recent captures grouped cleanly.
public struct HomeView: View {
    @ObservedObject private var dataStore = DataStore.shared
    @ObservedObject private var userSettings = UserSettings.shared

    @Binding public var captureSheetConfig: CaptureSheetConfig?
    @State private var selectedItemForDetail: CaptureItem?
    @State private var activeCategoryFilter: CaptureType? = nil

    public init(captureSheetConfig: Binding<CaptureSheetConfig?>) {
        self._captureSheetConfig = captureSheetConfig
    }

    private var formattedTodayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Capture Command Deck Card (Uses top space effectively)
                        heroCommandDeckCard

                        // Category Quick Filter Pills
                        categoryFilterBar

                        // Content Sections
                        if dataStore.items.isEmpty {
                            EmptyStateView(
                                icon: "bolt.badge.clock",
                                title: "Your personal capture inbox is empty",
                                subtitle: "Tap any category above or start typing to capture your first thought."
                            )
                            .padding(.top, 30)
                        } else {
                            if let filter = activeCategoryFilter {
                                filteredSection(for: filter)
                            } else {
                                defaultOverviewSections
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedItemForDetail) { item in
                CaptureDetailView(item: item)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero Capture Command Deck Card
    private var heroCommandDeckCard: some View {
        VStack(spacing: 16) {
            // Header Row: App Name with Catchy Mascot & Live Formatted Date
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    CatchyMascotView(pose: .mini, size: 32, animated: true)

                    Text("CATCH")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(Theme.primaryText)

                    Circle()
                        .fill(Theme.brandTint)
                        .frame(width: 6, height: 6)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)

                    Text(formattedTodayDate)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.secondaryBackground)
                .clipShape(Capsule())
            }

            // Central Quick Capture Input Capsule
            Button(action: {
                HapticsManager.shared.categorySelected()
                captureSheetConfig = CaptureSheetConfig(source: .text)
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.brandTint)
                            .frame(width: 36, height: 36)

                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("What's on your mind?")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.tertiaryText)

                    Spacer()

                    Button(action: {
                        HapticsManager.shared.categorySelected()
                        captureSheetConfig = CaptureSheetConfig(source: .voice)
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.brandTint)
                            .padding(8)
                            .background(Theme.brandTint.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            // Category 1-Tap Launcher Shortcuts Row
            HStack(spacing: 8) {
                categoryShortcutPill(type: .note)
                categoryShortcutPill(type: .idea)
                categoryShortcutPill(type: .task)
                categoryShortcutPill(type: .expense)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private func categoryShortcutPill(type: CaptureType) -> some View {
        Button(action: {
            HapticsManager.shared.categorySelected()
            captureSheetConfig = CaptureSheetConfig(category: type)
        }) {
            HStack(spacing: 5) {
                Image(systemName: type.iconName)
                    .font(.system(size: 11, weight: .semibold))
                Text(type.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(type.tintColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(type.tintColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" Pill
                filterChip(title: "All", count: dataStore.items.count, isSelected: activeCategoryFilter == nil) {
                    activeCategoryFilter = nil
                }

                ForEach(CaptureType.allCases) { category in
                    let count = dataStore.items(for: category).count
                    if count > 0 || activeCategoryFilter == category {
                        filterChip(
                            title: category.displayName,
                            count: count,
                            icon: category.iconName,
                            color: category.tintColor,
                            isSelected: activeCategoryFilter == category
                        ) {
                            if activeCategoryFilter == category {
                                activeCategoryFilter = nil
                            } else {
                                activeCategoryFilter = category
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterChip(
        title: String,
        count: Int,
        icon: String? = nil,
        color: Color = Theme.primaryText,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticsManager.shared.categorySelected()
            action()
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.25) : color.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .white : (icon != nil ? color : Theme.primaryText))
            .background(
                Capsule()
                    .fill(isSelected ? (icon != nil ? color : Theme.primaryText) : Theme.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Default Overview Sections
    private var defaultOverviewSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 1. Tasks Section (Incomplete tasks first)
            let activeTasks = dataStore.activeTasks
            if !activeTasks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "TASKS", count: activeTasks.count, color: Theme.accentSuccess)

                    VStack(spacing: 8) {
                        ForEach(activeTasks.prefix(5)) { item in
                            CaptureCardView(
                                item: item,
                                onToggleTask: {
                                    dataStore.toggleTask(id: item.id)
                                },
                                onTap: {
                                    selectedItemForDetail = item
                                }
                            )
                        }
                    }
                }
            }

            // 2. Ideas Section
            let ideas = dataStore.items(for: .idea)
            if !ideas.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "IDEAS", count: ideas.count, color: Theme.accentWarm)

                    VStack(spacing: 8) {
                        ForEach(ideas.prefix(3)) { item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                        }
                    }
                }
            }

            // 3. Notes Section
            let notes = dataStore.items(for: .note)
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "NOTES", count: notes.count, color: Theme.brandTint)

                    VStack(spacing: 8) {
                        ForEach(notes.prefix(3)) { item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                        }
                    }
                }
            }

            // 4. Expenses Section (with today total)
            let expenses = dataStore.items(for: .expense)
            if !expenses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionHeader(title: "EXPENSES", count: expenses.count, color: Theme.accentExpense)
                        Spacer()
                        if dataStore.todayExpenseTotal > 0 {
                            Text("Today: \(userSettings.defaultCurrency)\(Int(dataStore.todayExpenseTotal))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accentExpense)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.accentExpense.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    VStack(spacing: 8) {
                        ForEach(expenses.prefix(3)) { item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filtered Section
    private func filteredSection(for category: CaptureType) -> some View {
        let items = dataStore.items(for: category)
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: category.displayName.uppercased(), count: items.count, color: category.tintColor)

            if items.isEmpty {
                EmptyStateView(
                    icon: category.iconName,
                    title: "No \(category.displayName)s yet",
                    subtitle: "Tap + to capture your first \(category.displayName.lowercased())."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        CaptureCardView(
                            item: item,
                            onToggleTask: {
                                dataStore.toggleTask(id: item.id)
                            },
                            onTap: {
                                selectedItemForDetail = item
                            }
                        )
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.secondaryText)

            Text("(\(count))")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.tertiaryText)
        }
    }
}
