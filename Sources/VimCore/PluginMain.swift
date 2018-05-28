import Foundation
import VimInterface
import EditorService

func GetPluginDir() -> String {
    let f = String(#file).components(separatedBy: "/")
    return f[0..<(f.count - 3)].joined(separator: "/")
}

struct PluginState {
    let rpc: RPCRunner

    let statusTimer: VimTimer

    let editorService: VimProcess

    let editorSericeTask: VimTask<Void>

    init() {
        rpc = RPCRunner()
        rpc.start()

        let portValue = rpc.port.get()
        guard case let .ok(rpcPort) = portValue else {
            fatalError("Invalid port")
        }

        // FIXME: implement authorization
        let authToken = "TOK"
        let binPath = GetPluginDir() + "/.build/debug/spm-vim"

        let args = ["editor",  authToken, "--port", String(rpcPort)]
        let editorService = VimProcess.with(path: binPath, args: args)
        let statusTimer = VimTimer(timeInterval: 1.0)

        statusTimer.eventHandler = {
            if editorService.process.isRunning == false {
                print("swiftvim error: editorservice terminated")
            }
        }

        self.statusTimer = statusTimer
        self.editorService = editorService
        self.editorSericeTask = VimTask {
            editorService.process.launch()
            RunLoop.current.run()
        }
        editorSericeTask.run()
        statusTimer.resume()
    }
}

var state: PluginState?

// Core bootstrap
@_cdecl("plugin_init")
public func plugin_init(){
    swiftvim_initialize()
    state = PluginState()
}

