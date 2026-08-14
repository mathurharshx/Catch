import SwiftUI

/// Detailed view and editor for an individual capture item.
public struct CaptureDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataStore = DataStore.shared
    @ObservedObject private var userSettings = UserSettings.shared

    @State private var item: CaptureItem
    @State private var editedContent: String
    @State private var editedType: CaptureType
    @State private var editedAmountString: String
    @State private var editedMerchant: String
    @State private var editedReminderDate: Date?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showDatePicker: Bool = false

    public init(item: CaptureItem) {
        _item = State(initialValue: item)
        _editedContent = State(initialValue: item.content)
        _editedType = State(initialValue: item.type)
        _editedAmountString = State(initialValue: item.amount.map { "\($0)" } ?? "")
        _editedMerchant = State(initialValue: item.merchant ?? "")
        _editedReminderDate = State(initialValue: item.reminderDate)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Category Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.secondaryText)

                            HStack(spacing: 8) {
                                ForEach(CaptureType.allCases) { category in
                                    Button(action: {
                                        HapticsManager.shared.categorySelected()
                                        editedType = category
                                    }) {
                                        CategoryBadge(
                                            type: category,
                                            isSelected: editedType == category,
                                            showText: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Main Text Content Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONTENT")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.secondaryText)

                            TextEditor(text: $editedContent)
                                .font(.system(size: 16))
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)

                        // Task Completion Toggle if Task
                        if editedType == .task {
                            Toggle(isOn: $item.isCompleted) {
                                HStack {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isCompleted ? Theme.accentSuccess : Theme.secondaryText)
                                    Text("Mark as Completed")
                                        .font(.system(size: 15, weight: .medium))
                                }
                            }
                            .padding(14)
                            .background(Theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Expense Fields if Expense
                        if editedType == .expense {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("EXPENSE DETAILS")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.secondaryText)

                                HStack(spacing: 12) {
                                    HStack {
                                        Text(userSettings.defaultCurrency)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.accentExpense)
                                        TextField("Amount", text: $editedAmountString)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding(12)
                                    .background(Theme.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    TextField("Merchant / Description", text: $editedMerchant)
                                        .padding(12)
                                        .background(Theme.secondaryBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Reminder Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("REMINDER")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.secondaryText)

                            if let reminder = editedReminderDate {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(Theme.accentWarm)
                                    Text(reminder.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 14, weight: .medium))

                                    Spacer()

                                    Button(action: {
                                        editedReminderDate = nil
                                    }) {
                                        Text("Remove")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.accentExpense)
                                    }
                                }
                                .padding(14)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    HStack {
                                        Image(systemName: "bell")
                                            .foregroundColor(Theme.primaryText)
                                        Text("Add Reminder")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Theme.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.tertiaryText)
                                    }
                                    .padding(14)
                                    .background(Theme.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }

                            if showDatePicker {
                                DatePicker(
                                    "Reminder Date",
                                    selection: Binding(
                                        get: { editedReminderDate ?? Date().addingTimeInterval(3600) },
                                        set: { editedReminderDate = $0 }
                                    ),
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding(12)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 20)

                        // Metadata & Timestamps
                        VStack(alignment: .leading, spacing: 6) {
                            Text("INFO")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.secondaryText)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Captured:")
                                        .foregroundColor(Theme.secondaryText)
                                    Spacer()
                                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundColor(Theme.primaryText)
                                }
                                .font(.system(size: 13))

                                HStack {
                                    Text("Source:")
                                        .foregroundColor(Theme.secondaryText)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: item.source.iconName)
                                        Text(item.source.displayName)
                                    }
                                    .foregroundColor(Theme.primaryText)
                                }
                                .font(.system(size: 13))
                            }
                            .padding(14)
                            .background(Theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)

                        // Delete Action Button
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Delete Capture")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                            }
                            .padding(14)
                            .foregroundColor(Theme.accentExpense)
                            .background(Theme.accentExpense.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.secondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.brandTint)
                }
            }
            .confirmationDialog("Delete this capture?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    dataStore.delete(id: item.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        var updated = item
        updated.content = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.type = editedType
        updated.reminderDate = editedReminderDate

        if editedType == .expense {
            updated.amount = Double(editedAmountString)
            updated.merchant = editedMerchant.isEmpty ? nil : editedMerchant
        }

        dataStore.update(updated)
        dismiss()
    }
}
