import AppKit
import SwiftUI
import ServiceManagement

/// AppDelegate handles the application's lifecycle, acting as the entry point
/// for setting up the app's initial state, status bar item, and the eye rest manager.
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Manages the status bar icon and its associated popover (settings).
    var statusBarController: StatusBarController!
    /// Manages the core logic of the eye rest breaks, including timers and the full-screen overlay.
    var eyeRestManager: EyeRestManager!

    /// Called when the application has finished launching.
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
        
        // This ensures the login item is enabled/disabled when the user saves the setting.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    /// Called just before the application terminates.
    /// Use this for any final cleanup or saving of state if necessary.
    func applicationWillTerminate(_ notification: Notification) {
        // No specific cleanup needed here for this app's current functionality,
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
    }
    
    /// This method is called when `UserDefaults` values change.
    /// It specifically checks for changes to the `kLaunchAtLogin` key.
    @objc private func userDefaultsDidChange(_ notification: Notification) {
        let launchAtLoginKey = "launchAtLogin" // Must match the key used in SettingsView
        let defaults = UserDefaults.standard

        // Check if the changed key is our launchAtLogin key.
        // This is a simplified check; a more robust way would be to check the user info dict,
        // but for a single key this is usually sufficient after a manual set.
        // It relies on the fact that when you call UserDefaults.set, it triggers this notification.
        if defaults.object(forKey: launchAtLoginKey) != nil {
            let isEnabled = defaults.bool(forKey: launchAtLoginKey)
            setLaunchAtLogin(enabled: isEnabled)
        }
    }

    /// Enables or disables the application from launching automatically at login.
    /// - Parameter enabled: `true` to enable launch at login, `false` to disable.
    private func setLaunchAtLogin(enabled: Bool) {
        // The bundle identifier for your application.
        // Ensure this matches the bundle ID in your project settings (e.g., com.yourcompany.DigitalQuarantine).
        let bundleID = "com.bharath.Digital-Quarantine"
        
        // SMLoginItemSetEnabled is deprecated in newer macOS versions in favor of
        // ServiceManagement.shared.register(url:options:completion:) for sandboxed apps
        // or a new helper app approach for non-sandboxed apps.
        // However, for non-sandboxed apps, SMLoginItemSetEnabled is still commonly used
        // and works. For an agent app directly setting itself, this is typically fine.

        if SMLoginItemSetEnabled(bundleID as CFString, enabled) {
            print("Successfully set launch at login for \(bundleID) to: \(enabled)")
        } else {
            print("Failed to set launch at login for \(bundleID) to: \(enabled)")
        }
    }
}
