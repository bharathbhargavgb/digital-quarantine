import SwiftUI
import AppKit

class OverlayWindow: NSWindow {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backing, defer: `defer`)
        self.level = .screenSaver // Place it above all normal windows
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Crucial for full screen and across spaces
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.ignoresMouseEvents = false // We want to intercept mouse events
        self.canHide = false
        // REMOVE THIS LINE: self.makeKeyAndOrderFront(nil) // This was called too early
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func sendEvent(_ event: NSEvent) {
        // This is where the "undismissable" trick happens.
        // For now, we'll just process them normally but the goal
        // is to prevent the user from interacting with other apps.
        super.sendEvent(event)
    }
}
