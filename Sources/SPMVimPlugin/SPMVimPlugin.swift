import Foundation
import SPMVimPluginVim
import SPMVimPluginVimAsync

public func GetPluginDir() -> String {
    // TODO: Remove this
    let f = String(#file).components(separatedBy: "/")
    return f[0..<(f.count - 3)].joined(separator: "/")
}

/// Module instance
public final class SPMVimPlugin {
    let rpc: RPCRunner

    let statusTimer: VimTimer

    /// EditorService runs in a background process and
    /// pings the RPC service when necessary.
    let editorService: VimProcess

    let editorSericeTask: VimTask<Void>

    /// DiagnosticInterface listens to the RPC service for
    /// incoming diagnostics
    let diagUI: DiagnosticInterface

    init() {
        let diagUI: DiagnosticInterface = DiagnosticInterface()
        rpc = RPCRunner(observer: diagUI)
        rpc.start()

        let portValue = rpc.port.get()
        guard case let .ok(rpcPort) = portValue else {
            fatalError("Invalid port")
        }

        // FIXME: implement authorization
        let authToken = "TOK"
        let binPath = GetPluginDir() + "/.build/debug/spm-vim"

        let args = [
          "editor",
          authToken,
          "--port", String(rpcPort),
          "--path", (try? Vim.eval("expand('%:p')"))?.asString() ?? ""
        ]
        let editorService = VimProcess.with(path: binPath, args: args)
        let statusTimer = VimTimer(timeInterval: 1.0) {
            if editorService.process.isRunning == false {
                print("swiftvim error: editorservice terminated")
            }
        }

        self.statusTimer = statusTimer
        self.editorService = editorService
        self.editorSericeTask = VimTask {
            () -> Void in
            editorService.process.launch()
            RunLoop.current.run()
        }
        self.diagUI = diagUI
        editorSericeTask.run()
        statusTimer.resume()
    }

    static let shared = SPMVimPlugin()
}

