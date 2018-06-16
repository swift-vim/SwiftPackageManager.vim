// VimCore Plugin initialization
import VimCore

// Core bootstrap for the plugin
@_cdecl("spmvim_plugin_init")
public func plugin_init(context: UnsafePointer<Int8>) -> Int {
    // Setup the plugin conforming to <VimPlugin> here
    SetSharedPlugin(SPMPlugin())
    return 0
}

@_cdecl("spmvim_plugin_user_event")
public func plugin_user_event(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
    return HandlePluginEvent(event: event, context: context)
}

