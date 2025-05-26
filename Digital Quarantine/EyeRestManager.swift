import Foundation
import AppKit
import SwiftUI
import UserNotifications

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
    /// The timer that triggers a notification a specified time before the main break.
    private var notificationTimer: Timer?
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
    @AppStorage("notificationLeadSeconds") private var notificationLeadSeconds: Int = 30

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
        // Request notification authorization when the app starts.
        requestNotificationAuthorization()
    }

    /// Deinitializes the EyeRestManager, removing itself as an observer.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Requests user authorization for sending local notifications.
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }

    /// Called when UserDefaults (app settings) change. Restarts the main timer to apply new intervals.
    @objc private func settingsDidChange() {
        restartTimer()
    }

    /// Starts or restarts the main timer for eye rest breaks and schedules the pre-rest notification.
    func startTimer() {
        timer?.invalidate() // Invalidate any existing main timer.
        notificationTimer?.invalidate()

        let breakInterval = TimeInterval(intervalMinutes * 60)
        let notificationLead = TimeInterval(notificationLeadSeconds)

        // Ensure the main timer interval is at least 1 second.
        let safeBreakInterval = max(1.0, breakInterval)

        // Schedule the main timer to trigger the break.
        timer = Timer.scheduledTimer(timeInterval: safeBreakInterval, target: self, selector: #selector(triggerRest), userInfo: nil, repeats: true)
        print("Digital Quarantine main timer started. Next break in \(intervalMinutes) minutes (\(safeBreakInterval) seconds).")

        // Schedule the pre-rest notification if lead time is valid and less than the break interval.
        if notificationLead > 0 && notificationLead < safeBreakInterval {
            let notificationFireTime = safeBreakInterval - notificationLead
            notificationTimer = Timer.scheduledTimer(timeInterval: notificationFireTime, target: self, selector: #selector(showPreRestNotification), userInfo: nil, repeats: false) // One-shot timer
            print("Pre-rest notification scheduled for \(notificationFireTime) seconds before break.")
        } else {
            print("Pre-rest notification not scheduled (lead time 0 or too long/short).")
        }
    }

    /// Restarts the main timer, typically called after settings are changed.
    func restartTimer() {
        print("Restarting timer due to settings change...")
        timer?.invalidate() // Invalidate current main timer.
        notificationTimer?.invalidate()
        startTimer() // Start a new timer with potentially updated settings.
    }

    /// Called by `notificationTimer` to display a notification before the break starts.
    @objc private func showPreRestNotification() {
        sendLocalNotification(
            title: "Digital Quarantine Break Coming!",
            body: "Your eye rest break starts in \(notificationLeadSeconds) seconds. Get ready!"
        )
    }

    /// Helper method to send a local user notification.
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - body: The main content text of the notification.
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default // Use default notification sound.

        // Create a request to deliver the notification immediately.
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification sent: '\(title)'")
            }
        }
    }

    /// Called when the main timer fires, initiating an eye rest break.
    @objc private func triggerRest() {
        // Invalidate the notification timer here too, just in case it's still pending
        // and the main timer fired slightly early or was manually triggered.
        notificationTimer?.invalidate() // Invalidate pending notification
        
        print("Time for a break! Initiating break.")
        showOverlay() // Display the full-screen overlay.
        startRestCountdown() // Start the countdown for the break duration.
    }

    /// Displays the full-screen, undismissable overlay.
    private func showOverlay() {
        // ... (No functional changes here, only comments/prints removed) ...
        // All previous debug prints should be removed, as per cleanup request.
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
        // ... (No functional changes here, only comments/prints removed) ...
        DispatchQueue.main.async {
            self.overlayWindow?.orderOut(nil)
            self.overlayWindow = nil
            NSApp.activate(ignoringOtherApps: true)
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
    /// - Returns: A string containing a random instruction.
    private func getRandomInstruction() -> String {
        return eyeRestInstructions.randomElement() ?? "Take a deep breath."
    }
}
