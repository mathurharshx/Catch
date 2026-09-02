import SwiftUI

/// Settings, preferences, widget guide, and privacy overview.
public struct SettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var dataStore = DataStore.shared

    @State private var showExportSheet: Bool = false
    @State private var exportedJSONText: String = ""
    @State private var showClearConfirmation: Bool = false
    @State private var showWidgetGuide: Bool = false

    private let currencies = ["₹", "$", "€", "£", "¥", "CHF", "AED"]

    public init() {}

    public var body: some View {
        NavigationView {
            Form {
                // MARK: - Capture Defaults
                Section(header: Text("Capture Defaults")) {
                    Picker("Default Category", selection: $userSettings.defaultCategory) {
                        ForEach(CaptureType.allCases) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }

                    Picker("Default Currency", selection: $userSettings.defaultCurrency) {
                        ForEach(currencies, id: \.self) { symbol in
                            Text(symbol).tag(symbol)
                        }
                    }
                }

                // MARK: - Interaction & Speed
                Section(header: Text("Speed & Behavior")) {
                    Toggle("Auto-Focus Keyboard", isOn: $userSettings.autoFocusKeyboard)
                    Toggle("Haptic Feedback", isOn: $userSettings.enableHaptics)
                    Toggle("Open Capture on Launch", isOn: $userSettings.openCaptureOnColdLaunch)
                }

                // MARK: - Lock Screen & Widgets
                Section(header: Text("Lock Screen & Widgets")) {
                    Button(action: {
                        showWidgetGuide = true
                    }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(Theme.brandTint)
                            Text("How to add Lock Screen Widget")
                                .foregroundColor(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.tertiaryText)
                        }
                    }
                }

                // MARK: - Privacy & Data
                Section(header: Text("Privacy & Data")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(Theme.accentSuccess)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("100% On-Device Storage")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Your captures never leave your device without your explicit permission.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        exportedJSONText = dataStore.exportJSON()
                        showExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Captures (JSON)")
                        }
                        .foregroundColor(Theme.brandTint)
                    }

                    Button(role: .destructive, action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Captures")
                        }
                        .foregroundColor(Theme.accentExpense)
                    }
                }

                // MARK: - Mascot & Mission
                Section(header: Text("Meet Catchy")) {
                    HStack(spacing: 14) {
                        CatchyMascotView(pose: .noteTaker, size: 56, animated: true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Catchy the Elephant")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText)

                            Text("Because an elephant never forgets. Built for ADHD minds to capture thoughts before they slip away.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Product Identity
                Section(header: Text("About Catch")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Catch 1.0")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("“Whenever something enters your mind that you want to remember, save it immediately.”")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.secondaryText)
                            .italic()
                        Text("Capture First. Organize Later.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.brandTint)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                exportShareSheet
            }
            .sheet(isPresented: $showWidgetGuide) {
                widgetGuideSheet
            }
            .confirmationDialog("Clear all captures?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Delete All Captures", role: .destructive) {
                    dataStore.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all stored notes, tasks, ideas, and expenses from your device.")
            }
        }
    }

    // MARK: - Export Sheet
    private var exportShareSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("JSON Export Preview (\(dataStore.items.count) items)")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    Text(exportedJSONText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)

                Spacer()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: exportedJSONText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        showExportSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Widget Guide
    private var widgetGuideSheet: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Catch to your Lock Screen")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Experience true instant capture directly from your iPhone lock screen.")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        guideStepRow(
                            step: 1,
                            title: "Long press your Lock Screen",
                            subtitle: "Wake your iPhone, touch and hold the lock screen, then tap Customize."
                        )

                        guideStepRow(
                            step: 2,
                            title: "Select Lock Screen",
                            subtitle: "Tap on the Lock Screen preview, then tap the widget area below the clock."
                        )

                        guideStepRow(
                            step: 3,
                            title: "Add Catch Quick Capture",
                            subtitle: "Find Catch in the widget list and choose the Circular (+) or Rectangular widget."
                        )

                        guideStepRow(
                            step: 4,
                            title: "Tap Done",
                            subtitle: "Whenever something crosses your mind, tap the widget to capture it instantly."
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Lock Screen Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showWidgetGuide = false
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }

    private func guideStepRow(step: Int, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.brandTint)
                    .frame(width: 28, height: 28)
                Text("\(step)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding(14)
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
