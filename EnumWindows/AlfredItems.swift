import Foundation

extension WindowInfoDict : AlfredItem {
    var uid : String { return "1" };
    var title : String {
        if self.name.isEmpty {
            return self.processName
        }
        return self.name
    };
    var autocomplete : String { return self.title };
    var subtitle : String {
        return "Open window \(self.bundleURL?.path ?? self.processName)"
    };
    var arg: AlfredArg { return AlfredArg(arg1:self.processName, arg2:"\(self.tabIndex)", arg3:self.name) }
}

extension BrowserTab : AlfredItem {
    var uid : String { return "1" };
    var arg: AlfredArg { return AlfredArg(arg1:self.processName, arg2:"\(self.tabIndex)", arg3:self.windowTitle) }
    var autocomplete : String { return self.title };
    var subtitle : String { return "\(self.url)" };
}
