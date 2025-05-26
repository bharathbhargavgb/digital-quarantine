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
    /// The timer that triggers the status bar icon change before the main break.
    private var preRestIconTimer: Timer?
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
    @AppStorage("notificationLeadSeconds") private var preRestIconLeadSeconds: Int = 30

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

    /// Starts or restarts the main timer for eye rest breaks and schedules the pre-rest icon change.
    func startTimer() {
        timer?.invalidate() // Invalidate any existing main timer.
        preRestIconTimer?.invalidate() // Invalidate any existing pre-rest icon timer.

        let breakInterval = TimeInterval(intervalMinutes * 60)
        let iconLead = TimeInterval(preRestIconLeadSeconds) // Use the renamed property

        // Ensure the main timer interval is at least 1 second.
        let safeBreakInterval = max(1.0, breakInterval)

        // Schedule the main timer to trigger the break.
        timer = Timer.scheduledTimer(timeInterval: safeBreakInterval, target: self, selector: #selector(triggerRest), userInfo: nil, repeats: true)
        print("Digital Quarantine main timer started. Next break in \(intervalMinutes) minutes (\(safeBreakInterval) seconds).")

        // Schedule the pre-rest icon change if lead time is valid.
        if iconLead > 0 && iconLead < safeBreakInterval {
            let iconChangeFireTime = safeBreakInterval - iconLead
            preRestIconTimer = Timer.scheduledTimer(timeInterval: iconChangeFireTime, target: self, selector: #selector(changeIconForPreRest), userInfo: nil, repeats: false) // One-shot timer
            print("Pre-rest icon change scheduled for \(iconChangeFireTime) seconds before break.")
        } else {
            print("Pre-rest icon change not scheduled (lead time 0 or too long/short).")
        }
        // Ensure icon is default when timer starts (important if restarted after break).
        statusBarController?.updateIcon(.default)
    }

    /// Restarts the main timer, typically called after settings are changed.
    func restartTimer() {
        print("Restarting timer due to settings change...")
        timer?.invalidate()
        preRestIconTimer?.invalidate() // Invalidate pre-rest icon timer on restart.
        startTimer() // Starts new timers with updated settings.
    }

    /// Called by `preRestIconTimer` to change the status bar icon to the pre-rest indicator.
    @objc private func changeIconForPreRest() {
        statusBarController?.updateIcon(.preRest)
        print("Status bar icon changed to pre-rest indicator.")
    }

    /// Called when the main timer fires, initiating an eye rest break.
    @objc private func triggerRest() {
        // Invalidate the pre-rest icon timer here too, just in case it's still pending
        // and the main timer fired slightly early or was manually triggered.
        preRestIconTimer?.invalidate() // Invalidate pending icon change.

        print("Time for a break! Initiating break.")
        showOverlay() // Display the full-screen overlay.
        startRestCountdown() // Start the countdown for the break duration.
    }

    /// Displays the full-screen, undismissable overlay.
    private func showOverlay() {
        // ... (existing implementation - no functional changes here) ...
        DispatchQueue.main.async {
            let screenRect = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? NSRect.zero
            if screenRect.size.width == 0 || screenRect.size.height == 0 {
                print("ERROR: screenRect is zero or invalid, cannot show overlay!")
                return
            }

            self.overlayWindow = OverlayWindow(contentRect: screenRect, backing: .buffered, defer: false)
            if self.overlayWindow == nil {
                print("ERROR: OverlayWindow failed to initialize (is nil)! Check OverlayWindow.swift init.")
                return
            }

            self.overlayWindow?.contentViewController = NSHostingController(rootView:
                OverlayContentView(eyeRestManager: self, viewSize: screenRect.size)
            )

            if let hostingView = self.overlayWindow?.contentView {
                hostingView.wantsLayer = true
                hostingView.layer?.backgroundColor = NSColor.black.cgColor
            }

            NSApp.activate(ignoringOtherApps: true)
            self.overlayWindow?.makeKeyAndOrderFront(nil)
            self.overlayWindow?.orderFrontRegardless()
        }
    }

    /// Hides the full-screen overlay and reactivates the main application.
    private func hideOverlay() {
        DispatchQueue.main.async {
            self.overlayWindow?.orderOut(nil)
            self.overlayWindow = nil
            NSApp.activate(ignoringOtherApps: true)
            // Change icon back to default after rest period ends.
            self.statusBarController?.updateIcon(.default)
        }
    }

    /// Starts the countdown timer for the eye rest break duration.
    private func startRestCountdown() {
        currentCountdown = restSeconds
        currentInstruction = getRandomInstruction() + "\n(Look 20 feet away!)"

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.currentCountdown -= 1
            if self.currentCountdown <= 0 {
                timer.invalidate()
                self.hideOverlay()
                self.startTimer()
            }
        }
    }

    /// Returns a random eye rest instruction from the predefined list.
    private func getRandomInstruction() -> String {
        return eyeRestInstructions.randomElement() ?? "Take a deep breath."
    }
}
