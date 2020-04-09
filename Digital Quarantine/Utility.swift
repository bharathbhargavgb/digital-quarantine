//
//  Utility.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 4/12/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Foundation

class Utility {

    static func showNotification(subtitle: String, informativeText: String) {
        let notification = NSUserNotification()
        let epochTime = NSDate().timeIntervalSince1970
        notification.identifier = "quarantine-heads-up-\(epochTime)"
        notification.title = "Digital Quarantine"
        notification.subtitle = subtitle
        notification.informativeText = informativeText
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
