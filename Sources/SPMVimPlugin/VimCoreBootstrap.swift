// VimPlugin Plugin initialization
import SPMVimPluginVim
import SPMVimPluginVimAsync

/// plugin_load
/// Core bootstrap for the plugin.
/// This is called from Vimscript, when the plugin loads.
/// Non 0 return value indicates failure.
@_cdecl("SPMVimPlugin_plugin_load")
func plugin_load(context: UnsafePointer<Int8>) -> Int {
    _ = SPMVimPlugin.shared
    return 0
}

// Mark - Boilerplate

/// plugin_runloop_callback
/// This func is called from Vim to wakeup the main runloop
/// It isn't necessary for single threaded plugins
@_cdecl("SPMVimPlugin_plugin_runloop_callback")
func plugin_runloop_callback() {
    // Make sure to add VimAsync to the Makefile
    // and remove the comment.
    VimTaskRunLoopCallback()
}

/// plugin_runloop_invoke
/// This is called from Vim:
/// SPMVimPlugin.invoke("Func", 1, 2, 3)
/// The fact that this is here now is a current implementation
/// detail, and will likely go away in the future.
@_cdecl("SPMVimPlugin_plugin_invoke")
func plugin_invoke_callback(_ args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
    return VimPlugin.invokeCallback(args)
}

