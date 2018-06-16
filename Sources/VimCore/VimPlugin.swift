import Foundation
import VimInterface

/// VimPlugin is the main protocol for the plugin
public protocol VimPlugin {
    // Handle an event from Vim
    func pluginEvent(event id: Int, context: String) -> String?
}

private var SharedPlugin: VimPlugin?

/// Set the shared plugin
public func SetSharedPlugin(_ plugin: VimPlugin) {
    if SharedPlugin != nil {
        fatalError("Plugin already set")
    }
    SharedPlugin = plugin
}

public func HandlePluginEvent(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
    // FIXME: Move this somewhere else.
    // Ideally, this can be installed into Vim dynamically
    if event == 2 {
        InternalVimMainTheadCallback()
    }
    let ret = SharedPlugin?.pluginEvent(event: event,
        context: String(cString: context))
    return UnsafePointer<Int8>(ret)
}

