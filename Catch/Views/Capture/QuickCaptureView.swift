import SwiftUI
import Speech

/// The central Quick Capture interface in Catch.
/// Designed for ultra-fast, frictionless capture: Open -> Type/Speak -> Save -> Confirm -> Done.
public struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataStore = DataStore.shared
    @ObservedObject private var userSettings = UserSettings.shared
    @StateObject private var speechManager = SpeechManager.shared

    // Form State
    @State private var textContent: String = ""
    @State private var selectedCategory: CaptureType
    @State private var captureSource: CaptureSource = .text
    @State private var hasManuallySelectedCategory: Bool = false

    // Task-specific Checklist State
    @State private var checklistDrafts: [String] = []
    @State private var newChecklistDraft: String = ""
    @FocusState private var isChecklistFieldFocused: Bool

    // Optional Expense Specific State
    @State private var expenseAmountString: String = ""
    @State private var expenseMerchant: String = ""
    @State private var expenseCategoryTag: String = ""

    // Optional Reminder State
    @State private var showReminderPicker: Bool = false
    @State private var reminderDate: Date? = nil

    // UI Feedback State
    @State private var showConfirmation: Bool = false
    @State private var confirmationMessage: String = ""
    @State private var confirmationType: CaptureType = .note

    @FocusState private var isTextFieldFocused: Bool

    public init(initialCategory: CaptureType? = nil, initialSource: CaptureSource = .text) {
        let initialCat = initialCategory ?? UserSettings.shared.defaultCategory
        _selectedCategory = State(initialValue: initialCat)
        _captureSource = State(initialValue: initialSource)
        _hasManuallySelectedCategory = State(initialValue: initialCategory != nil)
    }

    private var isContentEmpty: Bool {
        textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedCategory != .task || (checklistDrafts.isEmpty && newChecklistDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category Selector Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CaptureType.allCases) { category in
                                Button(action: {
                                    HapticsManager.shared.categorySelected()
                                    withAnimation(Theme.springQuick) {
                                        selectedCategory = category
                                        hasManuallySelectedCategory = true
                                    }
                                }) {
                                    CategoryBadge(
                                        type: category,
                                        isSelected: selectedCategory == category,
                                        showText: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    Divider()
                        .background(Theme.border)

                    // Main Capture Input Area
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Text Input
                            ZStack(alignment: .topLeading) {
                                if textContent.isEmpty {
                                    Text(selectedCategory.placeholderText)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(Theme.tertiaryText)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }

                                TextEditor(text: $textContent)
                                    .font(.system(size: 18, weight: .regular))
                                    .scrollContentBackground(.hidden)
                                    .focused($isTextFieldFocused)
                                    .frame(minHeight: selectedCategory == .task ? 80 : 120, maxHeight: 200)
                                    .onChange(of: textContent) { oldValue, newValue in
                                        handleTextChange(newValue)
                                    }
                            }
                            .padding(.horizontal, 16)

                            // Live Audio Waveform when recording
                            if speechManager.isRecording {
                                AudioWaveformView(audioLevel: speechManager.audioLevel)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 16)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Task Checklist Section when in Task Mode
                            if selectedCategory == .task {
                                taskChecklistSection
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Optional Expense Fields when in Expense Mode
                            if selectedCategory == .expense {
                                expenseFieldsSection
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Reminder pill if active
                            if let reminder = reminderDate {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.accentWarm)

                                    Text(formatReminderDate(reminder))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.primaryText)

                                    Spacer()

                                    Button(action: {
                                        reminderDate = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                    .scrollIndicators(.hidden)

                    Spacer()

                    // Bottom Action Toolbar (Voice, Reminder, Checklist Add, Keyboard Dismiss)
                    bottomActionToolbar
                }

                // Satisfying Confirmation Banner Overlay
                if showConfirmation {
                    VStack {
                        ConfirmationToast(message: confirmationMessage, type: confirmationType)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .padding(.top, 8)
                    .zIndex(100)
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.secondaryText)
                            .padding(8)
                    }
                }

                // Clean Native Apple-Styled Save Action Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveCapture()
                    }) {
                        HStack(spacing: 5) {
                            Text("Save")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isContentEmpty ? Color.gray.opacity(0.35) : selectedCategory.tintColor)
                        )
                        .shadow(
                            color: isContentEmpty ? Color.clear : selectedCategory.tintColor.opacity(0.28),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isContentEmpty)
                    .animation(.easeInOut(duration: 0.18), value: isContentEmpty)
                }
            }
            .sheet(isPresented: $showReminderPicker) {
                reminderPickerSheet
            }
        }
        .onAppear {
            if userSettings.autoFocusKeyboard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
        .onReceive(speechManager.$transcribedText) { newTranscript in
            if speechManager.isRecording && !newTranscript.isEmpty {
                textContent = newTranscript
                captureSource = .voice
            }
        }
    }

    // MARK: - Task Checklist Section
    private var taskChecklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.accentSuccess)

                    Text("CHECKLIST ITEMS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                if !checklistDrafts.isEmpty {
                    Text("\(checklistDrafts.count) items")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.tertiaryText)
                }
            }
            .padding(.horizontal, 16)

            // Existing added checklist items
            ForEach(Array(checklistDrafts.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    Circle()
                        .stroke(Theme.accentSuccess, lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    Text(item)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.primaryText)

                    Spacer()

                    Button(action: {
                        HapticsManager.shared.light()
                        checklistDrafts.remove(at: index)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16)
            }

            // Quick-add next checklist item row
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.accentSuccess)

                TextField("Add checklist item...", text: $newChecklistDraft)
                    .font(.system(size: 15))
                    .focused($isChecklistFieldFocused)
                    .onSubmit {
                        addChecklistDraft()
                    }

                if !newChecklistDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: {
                        addChecklistDraft()
                    }) {
                        Text("Add")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accentSuccess)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accentSuccess.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.secondaryBackground.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private func addChecklistDraft() {
        let trimmed = newChecklistDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        HapticsManager.shared.light()
        withAnimation(Theme.springQuick) {
            checklistDrafts.append(trimmed)
            newChecklistDraft = ""
        }
    }

    // MARK: - Expense Section
    private var expenseFieldsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Expense Details (Optional)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.secondaryText)

            HStack(spacing: 12) {
                // Amount
                HStack(spacing: 4) {
                    Text(userSettings.defaultCurrency)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accentExpense)

                    TextField("Amount", text: $expenseAmountString)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15))
                }
                .padding(10)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Merchant
                TextField("Merchant/Place", text: $expenseMerchant)
                    .font(.system(size: 15))
                    .padding(10)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Bottom Toolbar (Cleaned of duplicate save button)
    private var bottomActionToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.border)

            HStack(spacing: 16) {
                // Voice Mic Button
                Button(action: {
                    toggleVoiceRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(speechManager.isRecording ? Theme.accentExpense : Theme.secondaryBackground)
                            .frame(width: 44, height: 44)

                        Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(speechManager.isRecording ? .white : Theme.primaryText)
                    }
                }
                .buttonStyle(.plain)

                // Quick Reminder Scheduler Button
                Button(action: {
                    HapticsManager.shared.categorySelected()
                    showReminderPicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(reminderDate != nil ? Theme.accentWarm.opacity(0.2) : Theme.secondaryBackground)
                            .frame(width: 44, height: 44)

                        Image(systemName: reminderDate != nil ? "bell.fill" : "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(reminderDate != nil ? Theme.accentWarm : Theme.primaryText)
                    }
                }
                .buttonStyle(.plain)

                // 1-Tap Task Checklist Tool (When in Task mode)
                if selectedCategory == .task {
                    Button(action: {
                        HapticsManager.shared.light()
                        isChecklistFieldFocused = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                                .font(.system(size: 14, weight: .bold))
                            Text("Checklist")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Theme.accentSuccess)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.accentSuccess.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Keyboard dismiss if focused
                if isTextFieldFocused || isChecklistFieldFocused {
                    Button(action: {
                        isTextFieldFocused = false
                        isChecklistFieldFocused = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.secondaryText)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(Theme.background)
    }

    // MARK: - Reminder Sheet
    private var reminderPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Reminder")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.top, 16)

                // Quick Presets
                VStack(spacing: 10) {
                    reminderPresetButton(title: "In 1 Hour", date: Date().addingTimeInterval(3600))
                    reminderPresetButton(title: "Tonight at 8:00 PM", date: targetTimeToday(hour: 20, minute: 0))
                    reminderPresetButton(title: "Tomorrow Morning at 9:00 AM", date: targetTimeTomorrow(hour: 9, minute: 0))
                }
                .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 20)

                // Custom Date Picker
                DatePicker(
                    "Custom Date & Time",
                    selection: Binding(
                        get: { reminderDate ?? Date().addingTimeInterval(3600) },
                        set: { reminderDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, 20)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showReminderPicker = false
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func reminderPresetButton(title: String, date: Date) -> some View {
        Button(action: {
            HapticsManager.shared.categorySelected()
            reminderDate = date
            showReminderPicker = false
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
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

    // MARK: - Actions

    private func handleTextChange(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if !hasManuallySelectedCategory {
                withAnimation(Theme.springQuick) {
                    selectedCategory = userSettings.defaultCategory
                }
            }
            return
        }

        // Proactive Zero-Touch Categorization if user hasn't manually overridden
        if !hasManuallySelectedCategory {
            let detection = CategoryDetector.detect(from: trimmed, defaultCurrency: userSettings.defaultCurrency)

            if detection.category != selectedCategory && detection.confidence >= 0.80 {
                withAnimation(Theme.springQuick) {
                    selectedCategory = detection.category
                }
                HapticsManager.shared.categorySelected()
            }

            if let parsedExpense = detection.parsedExpense {
                expenseAmountString = "\(parsedExpense.amount)"
                expenseMerchant = parsedExpense.merchant
            }
        }
    }

    private func toggleVoiceRecording() {
        HapticsManager.shared.voiceAction()
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            Task {
                let granted = await speechManager.requestAuthorization()
                if granted {
                    do {
                        try speechManager.startRecording()
                        captureSource = .voice
                    } catch {
                        print("Failed to start voice capture: \(error)")
                    }
                }
            }
        }
    }

    private func saveCapture() {
        var trimmed = textContent.trimmingCharacters(in: .whitespacesAndNewlines)

        // Include any pending draft item in the checklist
        var finalChecklistDrafts = checklistDrafts
        let pendingDraft = newChecklistDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pendingDraft.isEmpty {
            finalChecklistDrafts.append(pendingDraft)
        }

        if trimmed.isEmpty && selectedCategory == .task && !finalChecklistDrafts.isEmpty {
            trimmed = finalChecklistDrafts.first ?? "Task Checklist"
        }

        guard !trimmed.isEmpty else { return }

        if speechManager.isRecording {
            speechManager.stopRecording()
        }

        var amount: Double? = nil
        if let explicitAmount = Double(expenseAmountString) {
            amount = explicitAmount
        }

        let checklistItems: [ChecklistItem]? = selectedCategory == .task && !finalChecklistDrafts.isEmpty ?
            finalChecklistDrafts.map { ChecklistItem(title: $0, isCompleted: false) } : nil

        let saved = dataStore.save(
            content: trimmed,
            type: selectedCategory,
            source: captureSource,
            amount: amount,
            currency: userSettings.defaultCurrency,
            merchant: expenseMerchant.isEmpty ? nil : expenseMerchant,
            expenseCategory: expenseCategoryTag.isEmpty ? nil : expenseCategoryTag,
            reminderDate: reminderDate,
            checklistItems: checklistItems,
            transcription: captureSource == .voice ? trimmed : nil
        )

        // Show satisfying confirmation
        confirmationType = saved.type
        switch saved.type {
        case .note: confirmationMessage = "Catchy saved your note!"
        case .idea: confirmationMessage = "Catchy caught your idea!"
        case .task: confirmationMessage = checklistItems != nil ? "Catchy created your checklist!" : "Catchy recorded your task!"
        case .expense: confirmationMessage = "Catchy tracked your expense!"
        }

        withAnimation(Theme.springQuick) {
            showConfirmation = true
        }

        // Auto-dismiss after brief satisfying moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(Theme.springQuick) {
                showConfirmation = false
            }
            dismiss()
        }
    }

    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func targetTimeToday(hour: Int, minute: Int) -> Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comp.hour = hour
        comp.minute = minute
        return Calendar.current.date(from: comp) ?? Date().addingTimeInterval(3600)
    }

    private func targetTimeTomorrow(hour: Int, minute: Int) -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        comp.hour = hour
        comp.minute = minute
        return Calendar.current.date(from: comp) ?? Date().addingTimeInterval(86400)
    }
}
