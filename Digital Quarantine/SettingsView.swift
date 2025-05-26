import SwiftUI

/// A SwiftUI view for configuring the 20-20-20 rule parameters.
/// Settings are loaded when the view appears, and changes are applied and
/// validated only after the "Save" button is clicked.
struct SettingsView: View {
    // Environment property to dismiss the popover, available if needed (e.g., for Quit button).
    @Environment(\.dismiss) var dismiss

    // @State properties to temporarily hold input values from TextFields.
    // These are not directly linked to UserDefaults; changes are pending save.
    @State private var intervalMinutesInput: Int = 20
    @State private var restSecondsInput: Int = 20
    @State private var notificationLeadSecondsInput: Int = 30

    // State to track if any setting has been changed by the user.
    // This controls the enabled/disabled state of the Save button.
    @State private var isDirty: Bool = false

    // State for showing validation alerts when invalid input is detected.
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Constants for UserDefaults keys, promoting consistency and preventing typos.
    private let kIntervalMinutes = "intervalMinutes"
    private let kRestSeconds = "restSeconds"
    private let kNotificationLeadSeconds = "notificationLeadSeconds"

    var body: some View {
        VStack(spacing: 15) {
            Text("Digital Quarantine config")
                .font(.headline)

            HStack {
                Text("Every")
                // TextField bound to @State property. Validation is on save.
                TextField("", value: $intervalMinutesInput, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Mark view as dirty when input changes, enabling the Save button.
                    .onChange(of: intervalMinutesInput) { isDirty = true }
                Text("minutes")
            }

            HStack {
                Text("Rest for")
                // TextField bound to @State property. Validation is on save.
                TextField("", value: $restSecondsInput, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Mark view as dirty when input changes, enabling the Save button.
                    .onChange(of: restSecondsInput) { isDirty = true }
                Text("seconds")
            }

            HStack {
                Text("Notify")
                // TextField bound to @State property. Validation is on save.
                TextField("", value: $notificationLeadSecondsInput, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Mark view as dirty when input changes, enabling the Save button.
                    .onChange(of: notificationLeadSecondsInput) { isDirty = true }
                Text("seconds before break")
            }

            Divider()

            HStack {
                Button("Save") {
                    saveSettings() // Call the save method when button is clicked.
                }
                // The Save button is disabled if no changes have been made (`isDirty` is false).
                .disabled(!isDirty)
                // Assigns the Enter key as a keyboard shortcut for this button.
                .keyboardShortcut(.defaultAction)

                Button("Quit Digital Quarantine") {
                    NSApplication.shared.terminate(nil)
                }
                // Assigns the Escape key as a keyboard shortcut for this button.
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear {
            loadSettings() // Load initial settings from UserDefaults when the view first appears.
            isDirty = false // Reset dirty state after loading initial settings, as no changes have been made yet.
        }
        .alert(isPresented: $showingAlert) {
            // Display an alert for validation error messages.
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Loads the current settings from `UserDefaults` into the `@State` properties.
    /// Provides sensible default values if settings are not found (e.g., first launch or cleared defaults).
    private func loadSettings() {
        // `UserDefaults.standard.integer(forKey:)` returns 0 if a key is not found,
        // so we check for 0 to apply our intended defaults (20, 20, 30 respectively).
        intervalMinutesInput = UserDefaults.standard.integer(forKey: kIntervalMinutes) == 0 ? 20 : UserDefaults.standard.integer(forKey: kIntervalMinutes)
        restSecondsInput = UserDefaults.standard.integer(forKey: kRestSeconds) == 0 ? 20 : UserDefaults.standard.integer(forKey: kRestSeconds)
        notificationLeadSecondsInput = UserDefaults.standard.integer(forKey: kNotificationLeadSeconds) == 0 ? 30 : UserDefaults.standard.integer(forKey: kNotificationLeadSeconds)
    }

    /// Validates the input values and persists them to `UserDefaults` if valid.
    /// Shows an alert with error messages if validation fails.
    private func saveSettings() {
        var isValid = true
        var messages: [String] = []

        // --- Validation and Clamping Logic ---
        // These variables are declared as `let` as their values are set once
        // after clamping and then used for further validation and persistence.

        // Validate intervalMinutesInput: must be between 1 and 180.
        let validatedIntervalMinutes = clamp(intervalMinutesInput, min: 1, max: 180)
        if intervalMinutesInput != validatedIntervalMinutes {
            isValid = false
            messages.append("Interval (minutes) must be between 1 and 180.")
        }
        // Update the input field to display the clamped value, even if it was initially invalid.
        intervalMinutesInput = validatedIntervalMinutes

        // Calculate the maximum allowed value for rest and notification based on the validated interval.
        let maxDependentValue = (validatedIntervalMinutes * 60) / 4

        // Validate restSecondsInput: must be between 10 and (intervalMinutes * 60) / 4.
        let validatedRestSeconds = clamp(restSecondsInput, min: 10, max: maxDependentValue)
        if restSecondsInput != validatedRestSeconds {
            isValid = false
            messages.append("Rest (seconds) must be between 10 and \(maxDependentValue).")
        }
        restSecondsInput = validatedRestSeconds // Update input field to clamped value.

        // Validate notificationLeadSecondsInput: must be between 3 and (intervalMinutes * 60) / 4.
        let validatedNotificationLeadSeconds = clamp(notificationLeadSecondsInput, min: 3, max: maxDependentValue)
        if notificationLeadSecondsInput != validatedNotificationLeadSeconds {
            isValid = false
            messages.append("Notify (seconds) must be between 3 and \(maxDependentValue).")
        }
        notificationLeadSecondsInput = validatedNotificationLeadSeconds // Update input field to clamped value.

        // --- Persistence or Feedback ---
        if isValid {
            // If all inputs are valid, persist them to UserDefaults.
            UserDefaults.standard.set(validatedIntervalMinutes, forKey: kIntervalMinutes)
            UserDefaults.standard.set(validatedRestSeconds, forKey: kRestSeconds)
            UserDefaults.standard.set(validatedNotificationLeadSeconds, forKey: kNotificationLeadSeconds)

            print("Settings saved: Interval=\(validatedIntervalMinutes), Rest=\(validatedRestSeconds), Notify=\(validatedNotificationLeadSeconds)")

            isDirty = false // Reset dirty state, greying out the Save button.
        } else {
            // If validation fails, compile error messages and show an alert to the user.
            alertTitle = "Invalid Input"
            alertMessage = messages.joined(separator: "\n")
            showingAlert = true
        }
    }

    /// Helper function to clamp an integer value within a specified inclusive range.
    /// - Parameters:
    ///   - value: The input integer value.
    ///   - min: The minimum allowed value for the range.
    ///   - max: The maximum allowed value for the range.
    /// - Returns: The value clamped within the [min, max] range.
    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        return Swift.max(min, Swift.min(max, value))
    }
}
