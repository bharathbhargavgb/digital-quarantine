import SwiftUI
import AppKit

// Updated App struct name
@main
struct DigitalQuarantineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We don't need a WindowGroup for a menubar app without a main window
        Settings { // This is a placeholder, won't show a window
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var eyeRestManager: EyeRestManager! // Declare EyeRestManager here

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app doesn't show in the Dock
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController()
        eyeRestManager = EyeRestManager(statusBarController: statusBarController) // Pass controller for quit
        eyeRestManager.startTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up any resources if needed
    }
}
