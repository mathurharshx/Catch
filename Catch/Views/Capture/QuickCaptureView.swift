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
                    ScrollView {
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
                                    .frame(minHeight: 120, maxHeight: 220)
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
                    }

                    Spacer()

                    // Bottom Action Toolbar (Voice, Reminder, Save)
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveCapture()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : selectedCategory.tintColor)
                            )
                    }
                    .disabled(textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    // MARK: - Bottom Toolbar
    private var bottomActionToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.border)

            HStack(spacing: 20) {
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

                Spacer()

                // Keyboard dismiss if focused
                if isTextFieldFocused {
                    Button(action: {
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                // Instant Save Action
                Button(action: {
                    saveCapture()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))

                        Text("Save")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.4) : selectedCategory.tintColor)
                    )
                }
                .buttonStyle(.plain)
                .disabled(textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        let trimmed = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if speechManager.isRecording {
            speechManager.stopRecording()
        }

        var amount: Double? = nil
        if let explicitAmount = Double(expenseAmountString) {
            amount = explicitAmount
        }

        let saved = dataStore.save(
            content: trimmed,
            type: selectedCategory,
            source: captureSource,
            amount: amount,
            currency: userSettings.defaultCurrency,
            merchant: expenseMerchant.isEmpty ? nil : expenseMerchant,
            expenseCategory: expenseCategoryTag.isEmpty ? nil : expenseCategoryTag,
            reminderDate: reminderDate,
            transcription: captureSource == .voice ? trimmed : nil
        )

        // Show satisfying confirmation
        confirmationType = saved.type
        switch saved.type {
        case .note: confirmationMessage = "Catchy saved your note!"
        case .idea: confirmationMessage = "Catchy caught your idea!"
        case .task: confirmationMessage = "Catchy recorded your task!"
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
