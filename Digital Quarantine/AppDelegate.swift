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
    var eventMonitor: EventMonitor?

    // Starting point of application code
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        initApplication()
    }


    // Tear down application
    func applicationWillTerminate(_ aNotification: Notification) {
        reminder?.invalidate()
    }

    // Setup application
    func initApplication() {
        registerSystemNotifications()
        setStatusIcon()
        monitorToExitFocus()
        startApplicationInBackground()
    }

    func registerSystemNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWakeNote(note:)),
            name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
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
        reminder = Timer.scheduledTimer(timeInterval: UserPreferences.shared.sleepInterval, target: self, selector: #selector(dimDisplayPeriodically), userInfo: nil, repeats: true)
    }

    @objc func dimDisplayPeriodically(_ sender: Any?) {
        Utility.showNotification(subtitle: "You are about to be quarantined from this system", informativeText: "Brace for impact")

        DispatchQueue.main.asyncAfter(deadline: .now() + UserPreferences.shared.notificationHeadsUp) {
            self.toggleDisplayForPeriod()
        }
    }

    func toggleDisplayForPeriod() {
        let curLevels: [CGDirectDisplayID: Float] = BrightnessManager.shared.getBrightness()
        DispatchQueue.main.asyncAfter(deadline: .now() + UserPreferences.shared.sleepDuration) {
            self.resumeBrightness(targetLevels: curLevels)
        }
        restrictBrightness(displays: curLevels)
        DispatchQueue.main.asyncAfter(deadline: .now() + (UserPreferences.shared.sleepDuration * 0.3)) {
            let warningMessage = MischiefMonitor.monitorMischief()
            if !warningMessage.isEmpty {
                Utility.showNotification(subtitle: "", informativeText: warningMessage)
            }
        }
    }


    // Handle brightness changes
    func restrictBrightness(displays: [CGDirectDisplayID: Float]) {
        var restrictLevels = [CGDirectDisplayID: Float]()
        for displayID in displays.keys {
            restrictLevels[displayID] = UserPreferences.shared.dimnessLevel
        }
        BrightnessManager.shared.setBrightnessLevels(displayDict: restrictLevels)
    }

    func resumeBrightness(targetLevels: [CGDirectDisplayID: Float]) {
        BrightnessManager.shared.setBrightnessLevels(displayDict: targetLevels)
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

    // app sleep-wake selectors
    @objc func onWakeNote(note: NSNotification) {
        NSLog("App waking from sleep")
        startApplicationInBackground()
    }

    @objc func onSleepNote(note: NSNotification) {
        NSLog("App is going to sleep")
        reminder?.invalidate()
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
