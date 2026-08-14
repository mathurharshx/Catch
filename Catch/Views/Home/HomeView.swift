import SwiftUI

/// The minimalist Home screen showing recent captures grouped cleanly.
public struct HomeView: View {
    @ObservedObject private var dataStore = DataStore.shared
    @ObservedObject private var userSettings = UserSettings.shared

    @Binding public var isPresentingCapture: Bool
    @State private var selectedItemForDetail: CaptureItem?
    @State private var activeCategoryFilter: CaptureType? = nil

    public init(isPresentingCapture: Binding<Bool>) {
        self._isPresentingCapture = isPresentingCapture
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero Quick Capture Trigger Card
                        heroCaptureBanner

                        // Category Quick Filter Pills
                        categoryFilterBar

                        // Content Sections
                        if dataStore.items.isEmpty {
                            EmptyStateView(
                                icon: "bolt.badge.clock",
                                title: "Your personal capture inbox is empty",
                                subtitle: "Tap the capture bar above to save your first thought, task, or expense."
                            )
                            .padding(.top, 40)
                        } else {
                            if let filter = activeCategoryFilter {
                                filteredSection(for: filter)
                            } else {
                                defaultOverviewSections
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Catch")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticsManager.shared.categorySelected()
                        isPresentingCapture = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Theme.brandTint)
                    }
                }
            }
            .sheet(item: $selectedItemForDetail) { item in
                CaptureDetailView(item: item)
            }
        }
    }

    // MARK: - Hero Capture Banner
    private var heroCaptureBanner: some View {
        Button(action: {
            HapticsManager.shared.categorySelected()
            isPresentingCapture = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.brandTint)
                        .frame(width: 42, height: 42)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("What's on your mind?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text("Tap to capture in seconds")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.brandTint)
                    .padding(8)
                    .background(Theme.brandTint.opacity(0.12))
                    .clipShape(Circle())
            }
            .padding(14)
            .catchCard(cornerRadius: Theme.cornerRadiusLarge)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" Pill
                Button(action: {
                    HapticsManager.shared.categorySelected()
                    activeCategoryFilter = nil
                }) {
                    Text("All")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundColor(activeCategoryFilter == nil ? .white : Theme.primaryText)
                        .background(
                            Capsule()
                                .fill(activeCategoryFilter == nil ? Theme.primaryText : Theme.secondaryBackground)
                        )
                }
                .buttonStyle(.plain)

                ForEach(CaptureType.allCases) { category in
                    Button(action: {
                        HapticsManager.shared.categorySelected()
                        if activeCategoryFilter == category {
                            activeCategoryFilter = nil
                        } else {
                            activeCategoryFilter = category
                        }
                    }) {
                        CategoryBadge(
                            type: category,
                            isSelected: activeCategoryFilter == category,
                            showText: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
