//
//  ConfigureSheetController.swift
//  Padbury Clock Revived
//
//  Created by Hans Schülein on 2.2.2021.
//
//

import Cocoa

final class ConfigureSheetController: NSObject, NSTextFieldDelegate {

    @IBOutlet var window: NSWindow?
    
    // Outlets for the checkboxes to use
    @IBOutlet var versionStringLabel: NSTextField!
    
    @IBOutlet var appearanceSelector: NSPopUpButton!
    @IBOutlet var nightTimeModeCheckbox: NSButton!
    @IBOutlet var twentyfourHoursCheckbox: NSButton!
    @IBOutlet var showSecondsCheckbox: NSButton!
    @IBOutlet var showTimeSeparatorsCheckbox: NSButton!
    @IBOutlet var fontSelector: NSPopUpButton!
    @IBOutlet var fontWeightSelector: NSPopUpButton!
    @IBOutlet var plainFontsOnlyCheckbox: NSButton!
    @IBOutlet var mainScreenCheckbox: NSButton!
    @IBOutlet var footerMessageField: NSTextField!
    
    override init() {
        super.init()
        // Load the UI
        Bundle(for: ConfigureSheetController.self).loadNibNamed("ConfigureSheet", owner: self, topLevelObjects: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // OrionXV contribution: wire the footer field for live preference updates.
        footerMessageField.delegate = self
        setup()
    }
    
    func setup() {
        // Display the version number in the corner
        let bundle = Bundle(for: ConfigureSheetController.self)
        let versionNumber = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?.?.?"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?"
        versionStringLabel.stringValue = "v\(versionNumber) b\(buildNumber)"
        
        // Continue only if the preferences can be loaded
        guard let preferences = Preferences.shared else { return }
        
        // Remove all options from the appearance selectorand add the ones corresponding to the available ones
        appearanceSelector.removeAllItems()
        appearanceSelector.addItems(withTitles: Appearance.allCases.map({ $0.title }))
        appearanceSelector.selectItem(withTitle: preferences.appearance.title)
        
        // Set the checkboxes according to the settings
        nightTimeModeCheckbox.state = preferences.nightTimeMode ? .on : .off
        twentyfourHoursCheckbox.state = preferences.useAmPm ? .off : .on
        showSecondsCheckbox.state = preferences.showSeconds ? .on : .off
        showTimeSeparatorsCheckbox.state = preferences.showTimeSeparators ? .on : .off
        fontSelector.selectItem(withTitle: preferences.fontFamily.name)
        mainScreenCheckbox.state = preferences.mainScreenOnly ? .on : .off
        plainFontsOnlyCheckbox.state = preferences.plainFontsOnly ? .on : .off
        footerMessageField.stringValue = preferences.footerMessage
        
        // Remove all options from the font selector and add the ones corresponding to the fonts
        fontSelector.removeAllItems()
        fontSelector.addItems(withTitles: SupportedFont.allCases.map { $0.name })
        fontSelector.selectItem(withTitle: preferences.fontFamily.name)
        // Apply font style
        for (index, font) in SupportedFont.allCases.enumerated() {
            fontSelector.item(at: index)?.attributedTitle = NSAttributedString(string: font.name, attributes: [.font: NSFont(name: font.fontFamilyName, size: NSFont.systemFontSize) ?? NSFont.menuFont(ofSize: NSFont.systemFontSize)])
        }
        
        // Remove all the options from the font weight selector
        // and add the ones corresponding to the current font
        fontWeightSelector.removeAllItems()
        fontWeightSelector.addItems(withTitles: preferences.fontFamily.availableWeights)
        // Select the correct item
        // If the weight is not available for this font select the first option
        fontWeightSelector.selectItem(at: preferences.fontFamily.availableWeights.firstIndex(of: preferences.styleName) ?? 0)
        // Preview font
        for (index, typeName) in preferences.fontFamily.availableWeights.enumerated() {
            fontWeightSelector.item(at: index)?.attributedTitle = NSAttributedString(string: typeName, attributes: [.font: NSFont(name: preferences.fontFamily.postscriptName(for: typeName) ?? "", size: NSFont.systemFontSize) ?? NSFont.menuFont(ofSize: NSFont.systemFontSize)])
        }
        // Store said option back to the settings in case it changed
        preferences.styleName = fontWeightSelector.selectedItem?.title ?? ""
        
        // Trigger update of the preview window
        ClockView.shared?.setup(force: true)
    }
    
    @IBAction func toggledCheckbox(_ sender: NSObject) {
        // Write all settings once one was changed.
        
        // Continue only if the preferences can be loaded correctly
        guard let preferences = Preferences.shared else { return }
        preferences.appearance = Appearance.titled(appearanceSelector.titleOfSelectedItem ?? "") ?? .dark
        preferences.nightTimeMode = nightTimeModeCheckbox.state == .on
        preferences.useAmPm = twentyfourHoursCheckbox.state == .off
        preferences.showSeconds = showSecondsCheckbox.state == .on
        preferences.showTimeSeparators = showTimeSeparatorsCheckbox.state == .on
        preferences.fontFamily = SupportedFont.named(fontSelector.selectedItem?.title ?? "")
        preferences.styleName = fontWeightSelector.selectedItem?.title ?? ""
        preferences.mainScreenOnly = mainScreenCheckbox.state == .on
        preferences.plainFontsOnly = plainFontsOnlyCheckbox.state == .on
        preferences.footerMessage = footerMessageField.stringValue
        
        // Update the options. Font weight might have changed.
        self.setup()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, textField == footerMessageField else { return }
        guard let preferences = Preferences.shared else { return }

        // OrionXV contribution: update the preview immediately while the footer text changes.
        preferences.footerMessage = textField.stringValue
        ClockView.shared?.setup(force: true)
        ClockView.shared?.needsDisplay = true
    }
    
    @IBAction func closeConfigureSheet(_ sender: AnyObject) {
        // Close the sheet
        window?.sheetParent?.endSheet(window!)
    }
    
    @IBAction func openGithubLink(_ sender: Any) {
        // Open the link to the GitHub repository
        NSWorkspace.shared.open(URL(string: "https://github.com/Kamik423/Padbury-Clock-Revived")!)
    }
}
