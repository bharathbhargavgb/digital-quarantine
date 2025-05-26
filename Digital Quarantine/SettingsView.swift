import SwiftUI

/// A SwiftUI view for configuring the 20-20-20 rule parameters.
/// It uses `@AppStorage` to automatically persist settings to `UserDefaults`.
struct SettingsView: View {
    /// The interval in minutes between eye rest breaks. Default is 20.
    @AppStorage("intervalMinutes") var intervalMinutes: Int = 20
    /// The duration of the eye rest break in seconds. Default is 20.
    @AppStorage("restSeconds") var restSeconds: Int = 20
    /// The suggested distance in feet to look away during the break. Default is 20.
    @AppStorage("distanceFeet") var distanceFeet: Int = 20

    var body: some View {
        VStack(spacing: 15) {
            Text("20-20-20 Rule Configuration")
                .font(.headline)

            // Input field for the interval in minutes.
            HStack {
                Text("Every")
                TextField("", value: $intervalMinutes, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("minutes")
            }

            // Input field for the rest duration in seconds.
            HStack {
                Text("Rest for")
                TextField("", value: $restSeconds, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("seconds")
            }

            // Input field for the suggested looking distance in feet.
            HStack {
                Text("Look at something")
                TextField("", value: $distanceFeet, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("feet away")
            }

            Divider()

            // Button to quit the application.
            Button("Quit Digital Quarantine") {
                // Terminate the application when the button is clicked.
                NSApplication.shared.terminate(nil)
            }
            // Assigns the Escape key as a keyboard shortcut for this button.
            .keyboardShortcut(.cancelAction)
        }
        .padding() // Add padding around the VStack content.
        .frame(width: 300, height: 200) // Ensure consistent sizing for the popover.
    }
}
