//
//  MischiefMonitor.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 8/8/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Foundation

class MischiefMonitor {

    static let sev1Messages : [String] = [
        ""
    ]
    static let sev2Messages : [String] = [
        "If you think the current sleep preference isn't working out, please feel free to change it as required",
        "Please be conscious every time you override this behaviour. Don't do it unless absolutely required"
    ]
    static let sev3Messages : [String] = [
        "It can be tough to control this impulse, but make sure to try and improve next time",
        "The whole purpose of using this app is destroyed if you can't exercise self-control"
    ]
    static let sev4Messages : [String] = [
        "Staring at the screen for a prolonged duration is affecting your body more than you can imagine",
        "Computer Vision syndrome is a serious disease. Go check for yourself"
    ]
    static let sev5Messages : [String] = [
        "Am I a joke to you?",
        "Why did you even install the app in the first place?"
    ]

    static func monitorMischief() -> String {
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
        return getMessageForMischief(severity: streakCount)
    }

    static func getMessageForMischief(severity: Int) ->String {
        if severity <= 1 {
            let index = Int.random(in: 0 ..< sev1Messages.count)
            return sev1Messages[index]
        } else if severity == 2 {
            let index = Int.random(in: 0 ..< sev2Messages.count)
            return sev2Messages[index]
        } else if severity == 3 {
            let index = Int.random(in: 0 ..< sev3Messages.count)
            return sev3Messages[index]
        } else if severity == 4 {
            let index = Int.random(in: 0 ..< sev4Messages.count)
            return sev4Messages[index]
        }
        let index = Int.random(in: 0 ..< sev5Messages.count)
        return sev5Messages[index]
    }
}
