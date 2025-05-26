import Foundation
import AppKit
import SwiftUI // Import SwiftUI for ObservableObject

// Make EyeRestManager conform to ObservableObject
class EyeRestManager: NSObject, ObservableObject { // <--- ADDED ObservableObject here
    private var timer: Timer?
    private var restTimer: Timer?
    private var overlayWindow: OverlayWindow?
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
    @AppStorage("intervalMinutes") private var intervalMinutes: Int = 1
    @AppStorage("restSeconds") private var restSeconds: Int = 20
    @AppStorage("distanceFeet") private var distanceFeet: Int = 20

    // @Published properties will cause views observing this object to update
    @Published var currentCountdown: Int = 0
    @Published var currentInstruction: String = ""

    weak var statusBarController: StatusBarController?

    init(statusBarController: StatusBarController) {
        self.statusBarController = statusBarController
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func settingsDidChange() {
        restartTimer()
    }

    func startTimer() {
        timer?.invalidate()
        let interval = TimeInterval(intervalMinutes * 60)
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(triggerRest), userInfo: nil, repeats: true)
        print("Digital Quarantine timer started. Next rest in \(intervalMinutes) minutes.")
    }

    func restartTimer() {
        print("Restarting timer due to settings change...")
        timer?.invalidate()
        startTimer()
    }

    @objc private func triggerRest() {
        print("Time for a break!")
        showOverlay()
        startRestCountdown()
    }

    private func showOverlay() {
        print(">>> [EyeRestManager] showOverlay() called.")

        DispatchQueue.main.async {
            print(">>> [EyeRestManager] Inside main async block for overlay.")

            let screenRect = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? NSRect.zero
            let screenCGSize = screenRect.size // <--- Capture the size here

            print(">>> [EyeRestManager] screenRect: \(screenRect)")
            if screenRect.size.width == 0 || screenRect.size.height == 0 {
                print(">>> ERROR: [EyeRestManager] screenRect is zero or invalid, cannot show overlay!")
                return
            }

            self.overlayWindow = OverlayWindow(contentRect: screenRect, backing: .buffered, defer: false)

            print(">>> [EyeRestManager] OverlayWindow created instance: \(String(describing: self.overlayWindow))")
            if self.overlayWindow == nil {
                print(">>> ERROR: [EyeRestManager] OverlayWindow failed to initialize (is nil)! Check OverlayWindow.swift init.")
                return
            }

            // --- CRITICAL CHANGE: Pass the screenCGSize to OverlayContentView ---
            self.overlayWindow?.contentViewController = NSHostingController(rootView:
                OverlayContentView(eyeRestManager: self, viewSize: screenCGSize) // <--- Pass the new argument
            )

            print(">>> [EyeRestManager] NSHostingController with OverlayContentView set.")

            // Ensure the NSHostingController's view has a black layer background
            if let hostingView = self.overlayWindow?.contentView {
                hostingView.wantsLayer = true
                hostingView.layer?.backgroundColor = NSColor.black.cgColor
                print(">>> [EyeRestManager] Ensured hostingView is opaque and black via layer.")
            }

            NSApp.activate(ignoringOtherApps: true)
            print(">>> [EyeRestManager] NSApp.activate(ignoringOtherApps: true) called.")

            self.overlayWindow?.makeKeyAndOrderFront(nil)
            self.overlayWindow?.orderFrontRegardless()

            print(">>> [EyeRestManager] OverlayWindow ordered front and key.")
        }
    }

    private func hideOverlay() {
        DispatchQueue.main.async {
            self.overlayWindow?.orderOut(nil)
            self.overlayWindow = nil
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func startRestCountdown() {
        currentCountdown = restSeconds
        currentInstruction = getRandomInstruction() + "\n(Look \(distanceFeet) feet away!)"

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.currentCountdown -= 1
            if self.currentCountdown <= 0 {
                timer.invalidate()
                self.hideOverlay()
                print("Rest period ended. Resuming normal operation.")
                self.startTimer()
            }
        }
    }

    private func getRandomInstruction() -> String {
        return eyeRestInstructions.randomElement() ?? "Take a deep breath."
    }
}
