import SwiftUI

/// The minimalist Home screen featuring a pinned top header, sticky category filters, and 120Hz smooth scrolling.
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

    private var timeOfDayGreeting: (greeting: String, emoji: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return ("Good morning", "👋")
        case 12..<17:
            return ("Good afternoon", "☀️")
        case 17..<22:
            return ("Good evening", "✨")
        default:
            return ("Good night", "🌙")
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - 1 & 2. Liquid Glass Navigation & Filter Bar
                    VStack(spacing: 0) {
                        topPinnedHeader
                        pinnedCategoryFilterBar
                    }
                    .background(.ultraThinMaterial)
                    .overlay(
                        Divider().opacity(0.18),
                        alignment: .bottom
                    )
                    .zIndex(10)

                    // MARK: - 3. Smooth Scrollable Feed (120Hz ProMotion)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            // Quick Capture Bento Command Card
                            heroCommandDeckCard
                                .padding(.top, 12)

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
                        .padding(.top, 4)
                        .padding(.bottom, 95)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedItemForDetail) { item in
                CaptureDetailView(item: item)
            }
            .onOpenURL { url in
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let filterParam = components.queryItems?.first(where: { $0.name == "filter" })?.value,
                   let filterType = CaptureType(rawValue: filterParam.lowercased()) {
                    withAnimation(Theme.springQuick) {
                        activeCategoryFilter = filterType
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Pinned Top Header (Liquid Glass)
    private var topPinnedHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            // Mascot & App Title
            HStack(spacing: 8) {
                CatchyMascotView(pose: .catching, size: 36, animated: true)

                Text("Catch")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            // Date Badge
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)

                Text(formattedTodayDate)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Theme.secondaryBackground.opacity(0.75))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Pinned Category Filter Bar (Liquid Glass)
    private var pinnedCategoryFilterBar: some View {
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
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Hero Quick Capture Bento Command Card
    private var heroCommandDeckCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time-of-day Bento Greeting
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(timeOfDayGreeting.greeting) \(timeOfDayGreeting.emoji)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text(dataStore.items.isEmpty ? "What would you like to remember?" : "\(dataStore.items.count) thoughts safely caught")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)

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
            .buttonStyle(.tactile)

            // Category 1-Tap Tactile Launcher Shortcuts Row
            HStack(spacing: 8) {
                categoryShortcutPill(type: .note)
                categoryShortcutPill(type: .idea)
                categoryShortcutPill(type: .task)
                categoryShortcutPill(type: .expense)
            }
        }
        .padding(15)
        .catchCard(cornerRadius: Theme.cornerRadiusLarge)
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
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(type.tintColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(type.tintColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(type.tintColor.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.tactile)
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
        .buttonStyle(.tactile)
    }

    // MARK: - Default Overview Sections
    private var defaultOverviewSections: some View {
        VStack(alignment: .leading, spacing: 22) {
            // 1. Tasks Section (Incomplete tasks first)
            let activeTasks = dataStore.activeTasks
            if !activeTasks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "TASKS", count: activeTasks.count, color: Theme.accentSuccess)

                    VStack(spacing: 8) {
                        ForEach(Array(activeTasks.prefix(5).enumerated()), id: \.element.id) { index, item in
                            CaptureCardView(
                                item: item,
                                onToggleTask: {
                                    dataStore.toggleTask(id: item.id)
                                },
                                onTap: {
                                    selectedItemForDetail = item
                                }
                            )
                            .staggeredEntrance(index: index)
                            .fluidScrollTransition()
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
                        ForEach(Array(ideas.prefix(3).enumerated()), id: \.element.id) { index, item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                            .staggeredEntrance(index: 2 + index)
                            .fluidScrollTransition()
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
                        ForEach(Array(notes.prefix(3).enumerated()), id: \.element.id) { index, item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                            .staggeredEntrance(index: 4 + index)
                            .fluidScrollTransition()
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
                        ForEach(Array(expenses.prefix(3).enumerated()), id: \.element.id) { index, item in
                            CaptureCardView(
                                item: item,
                                onTap: { selectedItemForDetail = item }
                            )
                            .staggeredEntrance(index: 6 + index)
                            .fluidScrollTransition()
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
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        CaptureCardView(
                            item: item,
                            onToggleTask: {
                                dataStore.toggleTask(id: item.id)
                            },
                            onTap: {
                                selectedItemForDetail = item
                            }
                        )
                        .staggeredEntrance(index: index)
                        .fluidScrollTransition()
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
