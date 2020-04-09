//
//  MachineState.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 4/10/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Foundation

class MachineState {

    static func getBrightnessLevel() -> Float {
        var brightness: Float = 1.0
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        let result: kern_return_t = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)

        if result == kIOReturnSuccess {
            while service != 0 {
                service = IOIteratorNext(iterator)
                IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
                IOObjectRelease(service)
            }
        }
        return brightness
    }

    static func setBrightnessLevel(aLevel: Float) {
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess {
            var service: io_object_t = 1
            while service != 0 {
                service = IOIteratorNext(iterator)
                IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, aLevel)
                IOObjectRelease(service)
            }
        }
    }
}
