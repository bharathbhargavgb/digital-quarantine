//import CoreGraphics
//
//class EventTapManager {
//    private var eventTap: CFMachPort?
//
//    func enableEventTap() {
//        // Check Accessibility permission first:
//        guard AXIsProcessTrusted() else {
//            print("Accessibility permission not granted for event tap.")
//            return
//        }
//
//        // Create an event tap for keyboard down events
//        eventTap = CGEvent.tapCreate(
//            tap: .cgSessionEventTap,
//            place: .headInsertEventTap,
//            options: .defaultTap,
//            eventsOfInterest: [.keyDown, .flagsChanged], // Intercept key presses and modifier changes
//            callback: myEventTapCallback,
//            userInfo: nil
//        )
//
//        guard let eventTap = eventTap else {
//            print("Failed to create event tap.")
//            return
//        }
//
//        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//        CGEvent.tapEnable(tap: eventTap, enable: true)
//        print("Event tap enabled.")
//    }
//
//    func disableEventTap() {
//        if let eventTap = eventTap {
//            CGEvent.tapEnable(tap: eventTap, enable: false)
//            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0), .commonModes)
//            self.eventTap = nil
//            print("Event tap disabled.")
//        }
//    }
//
//    // Callback function for the event tap
//    private let myEventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
//        // Filter events only when the overlay is active
//        // You'd need a way to pass context from your EyeRestManager here
//        // e.g., a global variable or a weak reference in refcon (more complex)
//        let isOverlayActive = true // Replace with actual check
//
//        if isOverlayActive {
//            // Intercept Cmd+Q
//            if type == .keyDown {
//                let keyCode = event.keyCode
//                let commandKeyDown = event.flags.contains(.command)
//
//                if commandKeyDown && keyCode == 12 { // KeyCode for 'Q'
//                    print("Intercepted Cmd+Q - preventing termination.")
//                    return nil // Consume the event, preventing it from reaching the application
//                }
//            }
//        }
//        return Unmanaged.passRetained(event) // Allow other events to pass through
//    }
//}
