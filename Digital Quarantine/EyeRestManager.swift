import Foundation
import AppKit
import SwiftUI

/// Manages the core logic for the Digital Quarantine app, including:
/// - Scheduling regular eye rest breaks.
/// - Displaying a full-screen overlay during breaks.
/// - Managing a countdown timer on the overlay.
/// - Providing random eye rest instructions.
class EyeRestManager: NSObject, ObservableObject {
    /// The main timer that triggers eye rest breaks at a set interval.
    private var timer: Timer?
    /// The timer that manages the countdown during the eye rest break.
    private var restTimer: Timer?
    /// The custom NSWindow that creates the full-screen, undismissable overlay.
    private var overlayWindow: OverlayWindow?

    /// A list of random instructions to display during eye rest breaks.
    private var eyeRestInstructions: [String] = [
        "Relax your shoulders.",
        "Stand up and stretch.",
        "Do 10 push-ups (if safe!).",
        "Use the restroom.",
        "Grab a glass of water.",
        "Look out a window and focus on something distant.",
        "Close your eyes and breathe deeply.",
        "Roll your neck gently.",
        "Walk around for a bit.",
        "Do some jumping jacks.",
        "Rub your hands together to warm them, then place them over your closed eyes."
    ]

    /// Parameters for the 20-20-20 rule, stored in UserDefaults via @AppStorage.
    @AppStorage("intervalMinutes") private var intervalMinutes: Int = 20
    @AppStorage("restSeconds") private var restSeconds: Int = 20
    @AppStorage("distanceFeet") private var distanceFeet: Int = 20

    /// Published property for the current countdown value, observed by `OverlayContentView`.
    @Published var currentCountdown: Int = 0
    /// Published property for the current instruction text, observed by `OverlayContentView`.
    @Published var currentInstruction: String = ""

    /// A weak reference to the StatusBarController, primarily for potential app termination.
    weak var statusBarController: StatusBarController?

    /// Initializes the EyeRestManager.
    /// - Parameter statusBarController: The controller managing the status bar item.
    init(statusBarController: StatusBarController) {
        self.statusBarController = statusBarController
        super.init()
        // Observe changes to UserDefaults (settings) to restart the main timer if needed.
        NotificationCenter.default.addObserver(self, selector: #selector(settingsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }

    /// Deinitializes the EyeRestManager, removing itself as an observer.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Called when UserDefaults (app settings) change. Restarts the main timer to apply new intervals.
    @objc private func settingsDidChange() {
        restartTimer()
    }

    /// Starts or restarts the main timer for eye rest breaks.
    func startTimer() {
        timer?.invalidate() // Invalidate any existing timer to prevent multiple timers running.
        let interval = TimeInterval(intervalMinutes * 60)
        // Ensure the interval is at least 1 second to prevent issues with very small or zero intervals.
        let safeInterval = max(1.0, interval)

        // Schedule a repeating timer to call `triggerRest` after the specified interval.
        timer = Timer.scheduledTimer(timeInterval: safeInterval, target: self, selector: #selector(triggerRest), userInfo: nil, repeats: true)
        print("Digital Quarantine timer started. Next rest in \(intervalMinutes) minutes (\(safeInterval) seconds).")
    }

    /// Restarts the main timer, typically called after settings are changed.
    func restartTimer() {
        print("Restarting timer due to settings change...")
        timer?.invalidate() // Invalidate current timer.
        startTimer() // Start a new timer with potentially updated settings.
    }

    /// Called when the main timer fires, initiating an eye rest break.
    @objc private func triggerRest() {
        print("Time for a break! Initiating break.")
        showOverlay() // Display the full-screen overlay.
        startRestCountdown() // Start the countdown for the break duration.
    }

    /// Displays the full-screen, undismissable overlay.
    private func showOverlay() {
        print("showOverlay() called.")

        // Ensure UI updates and window operations happen on the main thread.
        DispatchQueue.main.async {
            print("Inside main async block for overlay.")

            // Get the primary screen's dimensions to make the overlay full screen.
            let screenRect = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? NSRect.zero

            print("screenRect: \(screenRect)")
            // Basic check to ensure valid screen dimensions were obtained.
            if screenRect.size.width == 0 || screenRect.size.height == 0 {
                print("ERROR: screenRect is zero or invalid, cannot show overlay!")
                return
            }

            // Initialize the custom overlay window with borderless style and screen saver level.
            self.overlayWindow = OverlayWindow(contentRect: screenRect, backing: .buffered, defer: false)

            print("OverlayWindow created instance: \(String(describing: self.overlayWindow))")
            // Check if the window was successfully created.
            if self.overlayWindow == nil {
                print("ERROR: OverlayWindow failed to initialize (is nil)! Check OverlayWindow.swift init.")
                return
            }

            // Host the SwiftUI `OverlayContentView` inside the `NSWindow`.
            // Pass `self` (EyeRestManager) as an `ObservedObject` and the `screenCGSize`
            // to ensure the SwiftUI content correctly fills the window.
            self.overlayWindow?.contentViewController = NSHostingController(rootView:
                OverlayContentView(eyeRestManager: self, viewSize: screenRect.size)
            )

            print("NSHostingController with OverlayContentView set.")

            // Explicitly configure the NSHostingController's underlying NSView.
            // This ensures the background is solid black and opaque, addressing previous rendering issues.
            if let hostingView = self.overlayWindow?.contentView {
                hostingView.wantsLayer = true // Enable layer-backed drawing.
                hostingView.layer?.backgroundColor = NSColor.black.cgColor // Set the layer's background color to black.
                print("Ensured hostingView is opaque and black via layer.")
            }

            // Activate the application to bring its windows to the foreground.
            // `ignoringOtherApps: true` attempts to force activation even if another app is active.
            NSApp.activate(ignoringOtherApps: true)
            print("NSApp.activate(ignoringOtherApps: true) called.")

            // Order the window to be key (receive events) and front (visible on top).
            self.overlayWindow?.makeKeyAndOrderFront(nil)
            // `orderFrontRegardless` ensures it's on top of all other windows, including full-screen apps.
            self.overlayWindow?.orderFrontRegardless()

            print("OverlayWindow ordered front and key.")
        }
    }

    /// Hides the full-screen overlay and reactivates the main application.
    private func hideOverlay() {
        DispatchQueue.main.async {
            self.overlayWindow?.orderOut(nil) // Hide the window.
            self.overlayWindow = nil // Release the window reference.
            // Reactivate the app (e.g., to bring its menubar icon back to normal focus).
            NSApp.activate(ignoringOtherApps: true)
            print("Overlay hidden and app activated.")
        }
    }

    /// Starts the countdown timer for the eye rest break duration.
    private func startRestCountdown() {
        currentCountdown = restSeconds // Initialize countdown with the configured rest duration.
        // Get a random instruction and append the distance suggestion.
        currentInstruction = getRandomInstruction() + "\n(Look \(distanceFeet) feet away!)"

        restTimer?.invalidate() // Invalidate any previous rest timer.
        // Schedule a repeating timer that fires every second.
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return } // Ensure self is still valid.
            self.currentCountdown -= 1 // Decrement the countdown.
            if self.currentCountdown <= 0 {
                timer.invalidate() // Stop the countdown timer.
                self.hideOverlay() // Hide the overlay.
                print("Rest period ended. Resuming normal operation.")
                self.startTimer() // Restart the main interval timer.
            }
        }
    }

    /// Returns a random eye rest instruction from the predefined list.
    /// - Returns: A string containing a random instruction.
    private func getRandomInstruction() -> String {
        return eyeRestInstructions.randomElement() ?? "Take a deep breath."
    }
}
