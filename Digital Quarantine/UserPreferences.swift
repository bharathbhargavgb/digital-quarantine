//
//  UserPreferences.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 4/10/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Foundation

class UserPreferences {

    var sleepInterval: Double = 0.0
    var sleepDuration: Double = 0.0
    var notificationHeadsUp: Double = 0.0
    var dimnessLevel: Float = 0.0

    init() {
    #if DEBUG
        sleepInterval = 15.0
        sleepDuration = 7.0
        notificationHeadsUp = 2.0
        dimnessLevel = 0.0
    #else
        sleepInterval = 20.0 * 60
        sleepDuration = 20.0
        notificationHeadsUp = 0.5 * 60
        dimnessLevel = 0.0
    #endif
    }
}
