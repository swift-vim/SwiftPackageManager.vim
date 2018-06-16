// VimKit Plugin initialization
import VimKit
import VimAsync

// Core bootstrap for the plugin
@_cdecl("spmvim_plugin_init")
public func plugin_init(context: UnsafePointer<Int8>) -> Int {
    // Setup the plugin conforming to <VimPlugin> here
    VimKit.setPlugin(SPMPlugin())
    return 0
}

@_cdecl("spmvim_plugin_event")
public func plugin_event(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
    return VimKit.event(event: event, context: context)
}

@_cdecl("spmvim_plugin_runloop_callback")
public func plugin_runloop_callback() {
    VimKit.runLoopCallback()
}

