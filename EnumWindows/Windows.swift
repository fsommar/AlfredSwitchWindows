import AppKit
import Foundation

class WindowInfoDict : Searchable, ProcessNameProtocol {
    private let windowInfoDict : Dictionary<NSObject, AnyObject>;
    
    init(rawDict : UnsafeRawPointer) {
        windowInfoDict = unsafeBitCast(rawDict, to: CFDictionary.self) as Dictionary
    }
    
    var name : String {
        return self.dictItem(key: "kCGWindowName", defaultValue: "")
    }
    
    var windowTitle: String {
        return self.name
    }
    
    var processName : String {
        return self.dictItem(key: "kCGWindowOwnerName", defaultValue: "")
    }
    
    var appName : String {
        return self.dictItem(key: "kCGWindowOwnerName", defaultValue: "")
    }
    
    var bundleURL: URL?

    var pid : pid_t {
        return self.dictItem(key: "kCGWindowOwnerPID", defaultValue: -1)
    }
    
    var bounds : CGRect {
        let dict = self.dictItem(key: "kCGWindowBounds", defaultValue: NSDictionary())
        guard let bounds = CGRect.init(dictionaryRepresentation: dict) else {
            return CGRect.zero
        }
        return bounds
    }
    
    var alpha : Float {
        return self.dictItem(key: "kCGWindowAlpha", defaultValue: 0.0)
    }
    
    var tabIndex: Int {
        return 0
    }
    
    func dictItem<T>(key : String, defaultValue : T) -> T {
        guard let value = windowInfoDict[key as NSObject] as? T else {
            return defaultValue
        }
        return value
    }
    
    static func == (lhs: WindowInfoDict, rhs: WindowInfoDict) -> Bool {
        return lhs.processName == rhs.processName && lhs.name == rhs.name
    }
    
    var hashValue: Int {
        return "\(self.processName)-\(self.name)".hashValue
    }
    
    var searchStrings: [String] {
        return [self.processName, self.name]
    }
    
    var isProbablyMenubarItem : Bool {
        // Our best guess, if it's very small and attached to the top of the screen, it is probably something
        // related to the menubar
        return self.bounds.minY <= 0 || self.bounds.height < 30
    }
    
    var isVisible : Bool {
        return self.alpha > 0
    }
}

struct Windows {
    static var all : [WindowInfoDict] {
        get {
            guard let wl = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) else {
                return []
            }
            let runningApps = NSWorkspace.shared()
                .runningApplications
                .filter { $0.activationPolicy == .regular }
                .reduce([pid_t : NSRunningApplication]()) { (acc, x) in
                    var dict = acc
                    dict[x.processIdentifier] = x
                    return dict
            }

            return (0..<CFArrayGetCount(wl)).flatMap { (i : Int) -> [WindowInfoDict] in
                guard let windowInfoRef = CFArrayGetValueAtIndex(wl, i) else {
                    return []
                }
                
                let wi = WindowInfoDict(rawDict: windowInfoRef)
                
                // We don't want to clutter our output with unnecessary windows that we can't switch to anyway.
                guard let app = runningApps[wi.pid], !wi.isProbablyMenubarItem && wi.isVisible else {
                    return []
                }
                wi.bundleURL = app.bundleURL
                return [wi]
            }
        }
    }
}
