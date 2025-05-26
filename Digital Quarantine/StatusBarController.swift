import SwiftUI
import AppKit

/// Manages the status bar item (menubar icon) for the Digital Quarantine app.
/// It handles showing and hiding the settings popover when the icon is clicked.
class StatusBarController: NSObject {
    /// The NSStatusItem instance that represents the icon in the macOS menubar.
    private var statusItem: NSStatusItem!
    /// The popover that displays the `SettingsView` when the status item is clicked.
    private var popover: NSPopover!
    /// Monitors global mouse events to dismiss the popover when the user clicks outside it.
    private var eventMonitor: EventMonitor?

    /// Initializes the status bar controller, setting up the icon, popover, and event monitor.
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    /// Configures the NSStatusItem, including its icon and action.
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Set a system symbol as the icon for the status bar.
            // "eye.fill" is a good choice for an eye-rest app.
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Digital Quarantine App")
            // Assign the action to be performed when the button is clicked.
            button.action = #selector(togglePopover(_:))
            // Set the target of the action to this controller instance.
            button.target = self
        }
    }

    /// Configures the NSPopover, including its size, behavior, and content view.
    private func setupPopover() {
        popover = NSPopover()
        // Define the preferred size of the popover content.
        popover.contentSize = NSSize(width: 300, height: 200)
        // Set behavior to .transient, so the popover dismisses when the user clicks outside it.
        popover.behavior = .transient
        // Host the SwiftUI SettingsView inside the popover.
        // SettingsView uses @AppStorage, so it doesn't need explicit bindings passed here.
        popover.contentViewController = NSHostingController(rootView: SettingsView())
    }

    /// Sets up an EventMonitor to detect clicks outside the popover, allowing it to dismiss.
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // If the popover is currently shown, hide it when an outside click occurs.
            if self?.popover.isShown == true {
                self?.hidePopover(event)
            }
        }
    }

    /// Toggles the visibility of the popover. Called when the status item button is clicked.
    /// - Parameter sender: The object that sent the action (typically the status item button).
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    /// Displays the popover relative to the status item button.
    /// - Parameter sender: The object that triggered the show action.
    private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            // Show the popover below the status item button.
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Start monitoring for outside clicks to dismiss the popover.
            eventMonitor?.start()
        }
    }

    /// Hides the popover.
    /// - Parameter sender: The object that triggered the hide action.
    private func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        // Stop monitoring for outside clicks once the popover is hidden.
        eventMonitor?.stop()
    }

    /// Terminates the application. This method is called from the SettingsView's "Quit" button.
    func quitApp() {
        NSApp.terminate(self)
    }
}
