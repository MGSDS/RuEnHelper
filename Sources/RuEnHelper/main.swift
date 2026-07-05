import AppKit
import Carbon
import Foundation

func findInputSource(forLanguage lang: String) -> TISInputSource? {
    let filter =
        [
            kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ] as CFDictionary

    guard
        let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource]
    else {
        return nil
    }

    for source in list {
        guard let langsPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages)
        else { continue }
        let langs = Unmanaged<CFArray>.fromOpaque(langsPtr).takeUnretainedValue() as? [String] ?? []
        if langs.first == lang {
            return source
        }
    }
    return nil
}

func switchLayout(toLanguage lang: String) {
    guard let source = findInputSource(forLanguage: lang) else {
        fputs("No enabled keyboard layout found for language '\(lang)'\n", stderr)
        return
    }
    let status = TISSelectInputSource(source)
    if status != noErr {
        fputs("TISSelectInputSource failed for '\(lang)': \(status)\n", stderr)
    }
}

let hotKeyEN: UInt32 = 1
let hotKeyRU: UInt32 = 2

func registerHotKey(keyCode: UInt32, id: UInt32) {
    var hotKeyRef: EventHotKeyRef?
    let hotKeyID = EventHotKeyID(signature: OSType(0x5255_454E), id: id)
    let modifiers = UInt32(controlKey | shiftKey)
    let status = RegisterEventHotKey(
        keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    if status != noErr {
        fputs("RegisterEventHotKey failed for id \(id): \(status)\n", stderr)
        exit(1)
    }
}

registerHotKey(keyCode: UInt32(kVK_ANSI_1), id: hotKeyEN)
registerHotKey(keyCode: UInt32(kVK_ANSI_2), id: hotKeyRU)

var eventSpec = EventTypeSpec(
    eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

InstallEventHandler(
    GetApplicationEventTarget(),
    { _, event, _ -> OSStatus in
        var hotKeyID = EventHotKeyID()
        GetEventParameter(
            event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
            nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
        switch hotKeyID.id {
        case hotKeyEN: switchLayout(toLanguage: "en")
        case hotKeyRU: switchLayout(toLanguage: "ru")
        default: break
        }
        return noErr
    }, 1, &eventSpec, nil, nil)

fputs("RuEnHelper running: Ctrl+Shift+1 -> EN, Ctrl+Shift+2 -> RU\n", stderr)
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
