//
//  PreferenceViewController.swift
//  Digital Quarantine
//
//  Created by Bharath Bhargav on 7/20/20.
//  Copyright © 2020 Unnecessary Labs. All rights reserved.
//

import Cocoa

class PreferenceViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet var sleepInterval: NSTextField!
    @IBOutlet var sleepDuration: NSTextField!
    @IBOutlet var notificationHeadsUp: NSTextField!
    @IBOutlet var preferenceStatus: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        let onlyIntFormatter = OnlyIntegerValueFormatter()
        sleepInterval.formatter = onlyIntFormatter
        sleepDuration.formatter = onlyIntFormatter
        notificationHeadsUp.formatter = onlyIntFormatter
    }
}

extension PreferenceViewController {
  // MARK: Storyboard instantiation
    static func freshController() -> PreferenceViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferenceViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PreferenceViewController else {
            fatalError("Why cant i find PreferenceViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
    
    // MARK: Actions
    @IBAction func update(_ sender: NSButton) {
        if sleepInterval.doubleValue <= 0 || sleepDuration.doubleValue <= 0 || notificationHeadsUp.doubleValue <= 0 ||
            sleepInterval.doubleValue * 60 < sleepDuration.doubleValue + notificationHeadsUp.doubleValue {
            preferenceStatus.stringValue = "Please enter a valid preference setting"
            return
        } else {
            preferenceStatus.stringValue = ""
        }

        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.preference.sleepInterval = sleepInterval.doubleValue * 60
        appDelegate.preference.sleepDuration = sleepDuration.doubleValue
        appDelegate.preference.notificationHeadsUp = notificationHeadsUp.doubleValue
        
        appDelegate.restartTimer()
    }
}

class OnlyIntegerValueFormatter: NumberFormatter {

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        // Optional: limit input length
        if partialString.count > 2 {
            return false
        }

        return Int(partialString) != nil
    }
}

@IBDesignable
class HyperlinkTextField: NSTextField {

    @IBInspectable var href: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.linkColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject,
        ]
        self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)
    }

    override func mouseDown(with theEvent: NSEvent) {
        if let localHref = URL(string: href) {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.closePopover(sender: self)
            NSWorkspace.shared.open(localHref)
        }
    }
}
