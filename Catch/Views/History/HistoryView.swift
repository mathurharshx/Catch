import SwiftUI

/// Chronological capture timeline and fast search.
/// Features a harmonized Liquid Glass header and fluid scrolling cards aligned with HomeView.
public struct HistoryView: View {
    @ObservedObject private var dataStore = DataStore.shared
    @State private var searchQuery: String = ""
    @State private var selectedCategoryFilter: CaptureType? = nil
    @State private var selectedItemForDetail: CaptureItem?

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - 1 & 2. Liquid Glass Pinned Navigation & Filter Bar (Aligned with Home)
                    VStack(spacing: 0) {
                        topPinnedHeader
                        searchFieldBar
                        pinnedCategoryFilterBar
                    }
                    .background(.ultraThinMaterial)
                    .overlay(
                        Divider().opacity(0.18),
                        alignment: .bottom
                    )
                    .zIndex(10)

                    // MARK: - 3. Chronological Timeline Feed (Fluid Scroll & Staggered Entrance)
                    let grouped = dataStore.groupedChronologically(
                        query: searchQuery,
                        category: selectedCategoryFilter
                    )

                    if grouped.isEmpty {
                        VStack {
                            Spacer()
                            if !searchQuery.isEmpty {
                                EmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "No results found",
                                    subtitle: "No captures match \"\(searchQuery)\""
                                )
                            } else {
                                EmptyStateView(
                                    icon: "clock.arrow.circlepath",
                                    title: "No history yet",
                                    subtitle: "Your captured thoughts and tasks will appear here chronologically."
                                )
                            }
                            Spacer()
                        }
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                                ForEach(Array(grouped.enumerated()), id: \.element.key) { groupIndex, group in
                                    Section(header: stickyHeaderView(title: group.key, count: group.items.count)) {
                                        VStack(spacing: 10) {
                                            ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, item in
                                                CaptureCardView(
                                                    item: item,
                                                    searchQuery: searchQuery,
                                                    onToggleTask: {
                                                        dataStore.toggleTask(id: item.id)
                                                    },
                                                    onTap: {
                                                        selectedItemForDetail = item
                                                    }
                                                )
                                                .staggeredEntrance(index: groupIndex * 3 + itemIndex)
                                                .fluidScrollTransition()
                                                .contextMenu {
                                                    if item.type == .task {
                                                        Button(action: {
                                                            dataStore.toggleTask(id: item.id)
                                                        }) {
                                                            Label(item.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: item.isCompleted ? "circle" : "checkmark.circle")
                                                        }
                                                    }
                                                    Button(role: .destructive, action: {
                                                        dataStore.delete(id: item.id)
                                                    }) {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 18)
                                    }
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 95)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedItemForDetail) { item in
                CaptureDetailView(item: item)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Pinned Top Header (Aligned with Home)
    private var topPinnedHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            // Mascot & App Title
            HStack(spacing: 8) {
                CatchyMascotView(pose: .noteTaker, size: 36, animated: true)

                Text("History")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            // Count Badge
            HStack(spacing: 5) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)

                Text("\(dataStore.items.count) items")
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
        .padding(.bottom, 4)
    }

    // MARK: - Search Field Bar (Matches Command Deck Input Styling)
    private var searchFieldBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.tertiaryText)

            TextField("Search notes, tasks, ideas...", text: $searchQuery)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.primaryText)

            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.secondaryBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: - Filter Pills Bar (Matches Home Category Filter Bar)
    private var pinnedCategoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" Pill
                filterChip(title: "All", count: dataStore.items.count, isSelected: selectedCategoryFilter == nil) {
                    selectedCategoryFilter = nil
                }

                ForEach(CaptureType.allCases) { category in
                    let count = dataStore.items(for: category).count
                    if count > 0 || selectedCategoryFilter == category {
                        filterChip(
                            title: category.displayName,
                            count: count,
                            icon: category.iconName,
                            color: category.tintColor,
                            isSelected: selectedCategoryFilter == category
                        ) {
                            if selectedCategoryFilter == category {
                                selectedCategoryFilter = nil
                            } else {
                                selectedCategoryFilter = category
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
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
        .buttonStyle(.tactile)
    }

    // MARK: - Sticky Date Header
    private func stickyHeaderView(title: String, count: Int) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.secondaryText)

            Spacer()

            Text("\(count) \(count == 1 ? "item" : "items")")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.tertiaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }
}
