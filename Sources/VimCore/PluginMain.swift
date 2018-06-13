import Foundation
import VimInterface

public func GetPluginDir() -> String {
    // TODO: Remove this
    let f = String(#file).components(separatedBy: "/")
    return f[0..<(f.count - 3)].joined(separator: "/")
}

public protocol VimPlugin {
    // Handle an event from Vim
    func pluginEvent(event id: Int, context: String) -> String?
}


