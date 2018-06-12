import VimCore
import Foundation

class SPMPlugin: VimPlugin {
    let rpc: RPCRunner

    let statusTimer: VimTimer

    let editorService: VimProcess

    let editorSericeTask: VimTask<Void>

    // TODO: find a way to read diags when the build updates
    let diagUI: DiagnosticInterface = DiagnosticInterface()

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
        editorSericeTask.run()
        statusTimer.resume()
    }

    func pluginEvent(event id: Int, context: String) -> String? {
        diagUI.onCursorMoved()
        return nil
    }
}

