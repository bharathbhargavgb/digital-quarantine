//
//  Utility.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 4/12/20.
//  Copyright © 2021 Unnecessary Labs. All rights reserved.
//

import Foundation

class Utility {
    static func thunder() {
        for _ in 0..<3 {
            BrightnessManager.shared.increaseBrightness()
            BrightnessManager.shared.increaseBrightness()
            usleep(100000)
            BrightnessManager.shared.decreaseBrightness()
            BrightnessManager.shared.decreaseBrightness()
            usleep(100000)
        }
    }
}
