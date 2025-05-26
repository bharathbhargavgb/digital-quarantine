import SwiftUI

/// A SwiftUI view for configuring the 20-20-20 rule parameters.
/// It uses `@AppStorage` to automatically persist settings to `UserDefaults`.
struct SettingsView: View {
    /// The interval in minutes between eye rest breaks. Default is 20.
    @AppStorage("intervalMinutes") var intervalMinutes: Int = 20
    /// The duration of the eye rest break in seconds. Default is 20.
    @AppStorage("restSeconds") var restSeconds: Int = 20
    /// The number of seconds before the break to show a notification. Default is 30.
    @AppStorage("notificationLeadSeconds") var notificationLeadSeconds: Int = 30 // <--- NEW PROPERTY

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

            // Input field for notification lead time
            HStack {
                Text("Notify")
                TextField("", value: $notificationLeadSeconds, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("seconds before break")
            }

            Divider()

            // Button to quit the application.
            Button("Quit Digital Quarantine") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        // Adjusted frame height to fit the new setting
        .frame(width: 300, height: 200)
    }
}
