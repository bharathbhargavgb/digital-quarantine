import AppKit

/// A helper class to monitor global system events (like mouse clicks).
/// Used primarily to detect clicks outside the popover to dismiss it.
class EventMonitor {
    /// The opaque reference to the event monitor.
    private var monitor: Any?
    /// The type of events to monitor (e.g., `.leftMouseDown`, `.rightMouseDown`).
    private let mask: NSEvent.EventTypeMask
    /// The closure to execute when a monitored event occurs.
    private let handler: (NSEvent?) -> Void

    /// Initializes an EventMonitor.
    /// - Parameters:
    ///   - mask: The event type mask specifying which events to monitor.
    ///   - handler: A closure that will be called when an event matching the mask occurs.
    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    /// Deinitializes the EventMonitor, ensuring the monitor is stopped.
    deinit {
        stop()
    }

    /// Starts monitoring for events.
    /// Adds a global event monitor that will call the handler when events matching the mask occur.
    public func start() {
        // `addGlobalMonitorForEvents` allows monitoring events even when the app is not active.
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    /// Stops monitoring for events.
    /// Removes the previously added global event monitor.
    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
