import SwiftUI
import AppKit

/// The main entry point for the Digital Quarantine macOS application.
/// This app runs as an agent (no Dock icon) and manages its lifecycle
/// through an AppDelegate.
@main
struct DigitalQuarantineApp: App {
    /// Adopts an NSApplicationDelegate to handle application lifecycle events,
    /// such as launching and setting up the status bar item and main timer.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Defines the app's scene graph. For an agent app without a main window,
    /// a placeholder `Settings` scene is used, containing an `EmptyView`.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
