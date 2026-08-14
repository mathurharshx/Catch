import SwiftUI

/// Chronological capture timeline and fast search.
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
                    // Category Filter Pills
                    filterPillsBar

                    // Timeline Content
                    let grouped = dataStore.groupedChronologically(
                        query: searchQuery,
                        category: selectedCategoryFilter
                    )

                    if grouped.isEmpty {
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
                    } else {
                        List {
                            ForEach(grouped, id: \.key) { group in
                                Section(header: sectionHeaderView(title: group.key, count: group.items.count)) {
                                    ForEach(group.items) { item in
                                        CaptureCardView(
                                            item: item,
                                            onToggleTask: {
                                                dataStore.toggleTask(id: item.id)
                                            },
                                            onTap: {
                                                selectedItemForDetail = item
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                dataStore.delete(id: item.id)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .safeAreaPadding(.bottom, 60)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search all captures..."
            )
            .sheet(item: $selectedItemForDetail) { item in
                CaptureDetailView(item: item)
            }
        }
    }

    // MARK: - Filter Pills
    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    HapticsManager.shared.categorySelected()
                    selectedCategoryFilter = nil
                }) {
                    Text("All")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundColor(selectedCategoryFilter == nil ? .white : Theme.primaryText)
                        .background(
                            Capsule()
                                .fill(selectedCategoryFilter == nil ? Theme.primaryText : Theme.secondaryBackground)
                        )
                }
                .buttonStyle(.plain)

                ForEach(CaptureType.allCases) { category in
                    Button(action: {
                        HapticsManager.shared.categorySelected()
                        if selectedCategoryFilter == category {
                            selectedCategoryFilter = nil
                        } else {
                            selectedCategoryFilter = category
                        }
                    }) {
                        CategoryBadge(
                            type: category,
                            isSelected: selectedCategoryFilter == category,
                            showText: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.background)
    }

    private func sectionHeaderView(title: String, count: Int) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.secondaryText)

            Spacer()

            Text("\(count) \(count == 1 ? "item" : "items")")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.tertiaryText)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}
