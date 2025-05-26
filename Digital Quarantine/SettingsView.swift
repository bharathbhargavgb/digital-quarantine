import SwiftUI

struct SettingsView: View {
    @AppStorage("intervalMinutes") var intervalMinutes: Int = 20
    @AppStorage("restSeconds") var restSeconds: Int = 20
    @AppStorage("distanceFeet") var distanceFeet: Int = 20

    var body: some View {
        VStack(spacing: 15) {
            Text("20-20-20 Rule Configuration")
                .font(.headline)

            HStack {
                Text("Every")
                TextField("", value: $intervalMinutes, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("minutes")
            }

            HStack {
                Text("Rest for")
                TextField("", value: $restSeconds, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("seconds")
            }

            HStack {
                Text("Look at something")
                TextField("", value: $distanceFeet, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("feet away")
            }

            Divider()

            Button("Quit EyeRest") {
                // This will terminate the application
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut(.cancelAction) // Assigns Escape key
        }
        .padding()
        .frame(width: 300, height: 200) // Ensure consistent sizing
    }
}
