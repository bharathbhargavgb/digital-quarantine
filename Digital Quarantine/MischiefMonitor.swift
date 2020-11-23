//
//  MischiefMonitor.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 8/8/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Foundation

class MischiefMonitor {

    static func monitorMischief() -> Int {
        let displayLevels = BrightnessManager.shared.getBrightness()
        let defaults = UserDefaults.standard
        var streakCount: Int = defaults.integer(forKey: "streakCount")

        var didCheat: Bool = false
        for (_, level) in displayLevels {
            if level > UserPreferences.shared.dimnessLevel {
                didCheat = true
                break
            }
        }
        if didCheat {
            streakCount += 1
        } else if streakCount > 0 {
            streakCount = 0
        }
        defaults.set(streakCount, forKey: "streakCount")
        return streakCount
    }
}
