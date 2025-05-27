import AppKit
import SwiftUI

/// AppDelegate handles the application's lifecycle, acting as the entry point
/// for setting up the app's initial state, status bar item, and the eye rest manager.
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Manages the status bar icon and its associated popover (settings).
    var statusBarController: StatusBarController!
    /// Manages the core logic of the eye rest breaks, including timers and the full-screen overlay.
    var eyeRestManager: EyeRestManager!

    // Constant for the Launch Agent preference key
    private let kEnableLaunchAgent = "enableLaunchAgent"
    // Constant for the Launch Agent's unique identifier (label)
    private let kAgentLabel = "com.bharath.Digital-Quarantine.agent"
    // Constant for the app's executable path within the bundle
    private let kAppExecutablePath = "/Applications/Digital Quarantine.app/Contents/MacOS/Digital Quarantine"

    /// This is where key components are initialized and the app's activation policy is set.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the application's activation policy to .accessory.
        // This makes the app run as an agent, meaning it won't appear in the Dock
        // or in the Cmd-Tab application switcher.
        NSApp.setActivationPolicy(.accessory)

        // Initialize the status bar controller, which sets up the menubar icon.
        statusBarController = StatusBarController()

        // Initialize the eye rest manager, passing the status bar controller
        // so it can potentially interact with it (e.g., for quitting the app).
        eyeRestManager = EyeRestManager(statusBarController: statusBarController)

        // Start the main timer for eye rest breaks.
        eyeRestManager.startTimer()

        // Observe changes to UserDefaults to manage the Launch Agent based on user preference.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    /// Called just before the application terminates.
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
    }

    /// This method is called when `UserDefaults` values change.
    /// It specifically checks for changes to the `kEnableLaunchAgent` key to update the Launch Agent's status.
    @objc private func userDefaultsDidChange(_ notification: Notification) {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.bool(forKey: kEnableLaunchAgent) // `bool(forKey)` returns false if key not set, which is a safe default.

        // Manage the launch agent based on the new 'enableLaunchAgent' preference.
        manageLaunchAgent(enabled: isEnabled)
    }

    /// Manages the Launch Agent (creates/deletes .plist and loads/unloads it via launchctl).
    /// - Parameter enabled: `true` to enable the Launch Agent, `false` to disable.
    private func manageLaunchAgent(enabled: Bool) {
        let fileManager = FileManager.default
        // Construct the full path to the LaunchAgents directory for the current user.
        guard let launchAgentsPath = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("LaunchAgents") else {
            print("Error: Could not find user's LaunchAgents directory.")
            return
        }
        let plistURL = launchAgentsPath.appendingPathComponent("\(kAgentLabel).plist")

        // The content of the Launch Agent .plist file.
        // Note: KeepAlive is set to false to prevent auto-relaunch after user quits.
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(kAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(kAppExecutablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardErrorPath</key>
            <string>/tmp/\(kAgentLabel).err</string>
            <key>StandardOutPath</key>
            <string>/tmp/\(kAgentLabel).out</string>
        </dict>
        </plist>
        """

        if enabled {
            // 1. Create LaunchAgents directory if it doesn't exist.
            if !fileManager.fileExists(atPath: launchAgentsPath.path) {
                do {
                    try fileManager.createDirectory(at: launchAgentsPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error creating LaunchAgents directory: \(error.localizedDescription)")
                    return
                }
            }

            // 2. Write the plist file to the LaunchAgents directory.
            do {
                try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
                print("Launch Agent plist written to: \(plistURL.path)")
            } catch {
                print("Error writing Launch Agent plist: \(error.localizedDescription)")
                return
            }

            // 3. Load the launch agent using `launchctl`.
            // `launchctl load -w` registers and loads the agent persistently.
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["load", "-w", plistURL.path]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    print("Successfully loaded Launch Agent: \(kAgentLabel)")
                } else {
                    print("Failed to load Launch Agent: \(kAgentLabel), status: \(process.terminationStatus)")
                }
            } catch {
                print("Error launching launchctl load: \(error.localizedDescription)")
            }
        } else { // If disabled, unload and remove the Launch Agent.
            // 1. Unload the launch agent using `launchctl`.
            // `launchctl unload -w` unregisters and unloads the agent persistently.
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["unload", "-w", plistURL.path]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    print("Successfully unloaded Launch Agent: \(kAgentLabel)")
                } else {
                    print("Failed to unload Launch Agent: \(kAgentLabel), status: \(process.terminationStatus)")
                }
            } catch {
                print("Error launching launchctl unload: \(error.localizedDescription)")
            }

            // 2. Remove the plist file.
            do {
                if fileManager.fileExists(atPath: plistURL.path) {
                    try fileManager.removeItem(at: plistURL)
                    print("Launch Agent plist removed from: \(plistURL.path)")
                }
            } catch {
                print("Error removing Launch Agent plist: \(error.localizedDescription)")
            }
        }
    }
}
