import AppKit
import SwiftUI

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
    }

    /// Called just before the application terminates.
    /// Use this for any final cleanup or saving of state if necessary.
    func applicationWillTerminate(_ notification: Notification) {
        // No specific cleanup needed here for this app's current functionality,
        // but it's a good placeholder.
    }
}
