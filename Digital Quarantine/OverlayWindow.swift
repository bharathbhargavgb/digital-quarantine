import SwiftUI
import AppKit
import QuartzCore

/// A custom NSWindow subclass designed to create a full-screen, borderless, and high-level overlay.
/// It's configured to appear above most other windows and intercept mouse events.
class OverlayWindow: NSWindow {
    /// Initializes the overlay window with specific properties for full-screen display.
    /// - Parameters:
    ///   - contentRect: The initial content rectangle of the window (typically the screen bounds).
    ///   - backing: The backing store type for the window.
    ///   - defer: A boolean indicating whether the window's creation should be deferred.
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer: Bool) {
        // Initialize with borderless style, which removes title bar and resize controls.
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backing, defer: `defer`)
        // Set the window level to .screenSaver to ensure it appears above most applications.
        self.level = .screenSaver
        // Configure collection behavior to join all spaces and act as a full-screen auxiliary window.
        // This helps it appear correctly in full-screen modes and across multiple desktop spaces.
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = true // Declare the window as opaque for better rendering performance.
        self.backgroundColor = .black // Set the window's background color to black.
        self.hasShadow = false // Remove any window shadows.
        self.ignoresMouseEvents = false // Important: Do NOT ignore mouse events, so clicks are intercepted.
        self.canHide = false // Prevent the window from being hidden by standard means.
        self.alphaValue = 0.0 // Start the window fully transparent
        // Note: `makeKeyAndOrderFront(nil)` is called by EyeRestManager AFTER content is set.
    }

    /// Overrides to allow the window to become the key window, enabling it to receive keyboard events.
    override var canBecomeKey: Bool {
        return true
    }

    /// Overrides to allow the window to become the main window.
    override var canBecomeMain: Bool {
        return true
    }

    /// Intercepts all incoming events for this window.
    /// This is a hook for more advanced "undismissable" behavior if needed,
    /// such as consuming Cmd+Q events (requires Accessibility permissions).
    /// - Parameter event: The NSEvent that occurred.
    override func sendEvent(_ event: NSEvent) {
        // For now, events are passed through to allow default system handling,
        // but the window's properties (level, ignoresMouseEvents) already
        // make it difficult to interact with underlying applications.
        super.sendEvent(event)
    }
}
