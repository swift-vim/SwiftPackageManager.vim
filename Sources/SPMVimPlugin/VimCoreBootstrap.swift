// This API should exisit at the plugin level.
// C functions at the global scope should be namespaced to the plugin name.
import VimCore

// Core bootstrap for the plugin
@_cdecl("plugin_init")
public func plugin_init(context: UnsafePointer<Int8>) -> Int {
    SetSharedPlugin(SPMPlugin())
    return 0
}

private var SharedPlugin: VimPlugin?

/// Set the shared plugin
public func SetSharedPlugin(_ plugin: VimPlugin) {
    if SharedPlugin != nil {
        fatalError("Plugin already set")
    }
    SharedPlugin = plugin
}

@_cdecl("plugin_user_event")
public func plugin_user_event(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
    let ret = SharedPlugin?.pluginEvent(event: event,
        context: String(cString: context))
    return UnsafePointer<Int8>(ret)
}
