//
//  AppDelegate.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 4/9/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var reminder: Timer?
    var preference = UserPreferences()
    var eventMonitor: EventMonitor?

    // Starting point of application code
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        if permittedToRun() {
            initApplication()
        } else {
            NSApplication.shared.terminate(self)
        }
    }


    // Tear down application
    func applicationWillTerminate(_ aNotification: Notification) {
        reminder?.invalidate()
    }


    // Acquire Accessibility privilege
    func permittedToRun() -> Bool {
        if readPrivileges(shouldPrompt: false) == false {
            showAlertPopup()
            _ = readPrivileges(shouldPrompt: true)
            return false
        }
        return true
    }

    private func showAlertPopup() {
        let alert: NSAlert = NSAlert()
        alert.messageText = "Accessibility permission required"
        alert.informativeText = "Please enable Accessibility permission in Settings -> Security & Privacy and re-open the application"
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func readPrivileges(shouldPrompt: Bool) -> Bool {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: shouldPrompt] as CFDictionary
        let status = AXIsProcessTrustedWithOptions(privOptions)
        return status
    }


    // Setup application
    func initApplication() {
        DistributedNotificationCenter.default().removeObserver(self, name: NSNotification.Name("com.apple.accessibility.api"), object: nil)
        setStatusIcon()
        monitorToExitFocus()
        startApplicationInBackground()
    }

    func setStatusIcon() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("Pigeon"))
            /* <a target="_blank" href="https://icons8.com/icons/set/peace-pigeon">Peace Pigeon icon</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a> */
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = PreferenceViewController.freshController()
    }
    
    func monitorToExitFocus() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }


    // Start timer with user preferences
    func startApplicationInBackground() {
        UserDefaults.standard.set(0, forKey: "streakCount")
        reminder = Timer.scheduledTimer(timeInterval: preference.sleepInterval, target: self, selector: #selector(dimDisplayPeriodically), userInfo: nil, repeats: true)
    }

    @objc func dimDisplayPeriodically(_ sender: Any?) {
        Utility.showNotification(subtitle: "You are about to be quarantined from this system", informativeText: "Brace for impact")

        DispatchQueue.main.asyncAfter(deadline: .now() + preference.notificationHeadsUp) {
            self.toggleDisplayForPeriod()
        }
    }

    func toggleDisplayForPeriod() {
        let brightness = MachineState.getBrightnessLevel()
        DispatchQueue.main.asyncAfter(deadline: .now() + preference.sleepDuration) {
            self.resumeBrightness(targetBrightness: brightness)
        }
        restrictBrightness()
        DispatchQueue.main.asyncAfter(deadline: .now() + (preference.sleepDuration * 0.3)) {
            let warningMessage = MischiefMonitor.monitorMischief()
            if !warningMessage.isEmpty {
                Utility.showNotification(subtitle: "", informativeText: warningMessage)
            }
        }
    }


    // Handle brightness changes
    func restrictBrightness() {
        var brightness = MachineState.getBrightnessLevel()
        while brightness > preference.dimnessLevel {
            changeBrightness(code: NX_KEYTYPE_BRIGHTNESS_DOWN)
            Thread.sleep(forTimeInterval: 0.1)
            brightness = MachineState.getBrightnessLevel()
        }
    }

    func resumeBrightness(targetBrightness: Float) {
        var brightness = MachineState.getBrightnessLevel()
        while brightness < targetBrightness {
            changeBrightness(code: NX_KEYTYPE_BRIGHTNESS_UP)
            Thread.sleep(forTimeInterval: 0.1)
            brightness = MachineState.getBrightnessLevel()
        }
        MachineState.setBrightnessLevel(aLevel: targetBrightness)
        NSLog("Expected brightness: \(targetBrightness)")
        brightness = MachineState.getBrightnessLevel()
        NSLog("Current brightness : \(brightness)")
    }

    func changeBrightness(code: Int32) {
        let event1 = NSEvent.otherEvent(with: .systemDefined, location: NSPoint.zero, modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00), timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: (Int((code << 16 as Int32) | (0xa << 8 as Int32))), data2: -1)
        event1?.cgEvent?.post(tap: .cghidEventTap)
        let event2 = NSEvent.otherEvent(with: .systemDefined, location: NSPoint.zero, modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00), timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: (Int((code << 16 as Int32) | (0xb << 8 as Int32))), data2: -1)
        event2?.cgEvent?.post(tap: .cghidEventTap)
    }


    // Preference pane UX helpers
    @objc func togglePopover(_ sender: Any?) {
      if popover.isShown {
        closePopover(sender: sender)
      } else {
        showPopover(sender: sender)
      }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    func restartTimer() {
        reminder?.invalidate()
        startApplicationInBackground()
        closePopover(sender: self)
    }
}

// Extension for Notification delegate
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}
