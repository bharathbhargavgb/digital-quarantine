import SwiftUI
import AppKit

/// Defines the types of icons for the status bar to represent different states.
enum IconType {
    case `default` // The standard icon (eye.fill)
    case preRest // The icon indicating a break is coming soon (eye.square.fill)
}

/// Manages the status bar item (menubar icon) for the Digital Quarantine app.
/// It handles showing and hiding the settings popover when the icon is clicked.
class StatusBarController: NSObject {
    /// The NSStatusItem instance that represents the icon in the macOS menubar.
    private var statusItem: NSStatusItem!
    /// The popover that displays the `SettingsView` when the status item is clicked.
    private var popover: NSPopover!
    /// Monitors global mouse events to dismiss the popover when the user clicks outside it.
    private var eventMonitor: EventMonitor?

    /// Keeps track of the current icon type to avoid redundant updates.
    private var currentIconType: IconType = .default

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
            // Set the initial default icon.
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Digital Quarantine App")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    /// Configures the NSPopover, including its size, behavior, and content view.
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())
    }

    /// Sets up an EventMonitor to detect clicks outside the popover, allowing it to dismiss.
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.hidePopover(event)
            }
        }
    }

    /// Toggles the visibility of the popover. Called when the status item button is clicked.
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    /// Displays the popover relative to the status item button.
    private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }

    /// Hides the popover.
    private func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    /// Updates the status bar icon based on the specified `IconType`.
    /// - Parameter type: The desired `IconType` to set.
    func updateIcon(_ type: IconType) {
        // Only update the icon if the type is different to avoid unnecessary UI redraws.
        guard currentIconType != type else { return }

        currentIconType = type // Update the internal state.

        if let button = statusItem.button {
            switch type {
            case .default:
                button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Digital Quarantine App")
            case .preRest:
                button.image = NSImage(systemSymbolName: "eyes", accessibilityDescription: "Digital Quarantine Break Soon")
            }
        }
    }

    /// Terminates the application. This method is called from the SettingsView's "Quit" button.
    func quitApp() {
        NSApp.terminate(self)
    }
}
