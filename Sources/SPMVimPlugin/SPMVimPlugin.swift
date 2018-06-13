import VimCore
import Foundation

class SPMPlugin: VimPlugin {
    let rpc: RPCRunner

    let statusTimer: VimTimer

    let editorService: VimProcess

    let editorSericeTask: VimTask<Void>
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
          "--path", Vim.eval("expand('%:p')").asString() ?? ""
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

    enum SPMVimEvent: Int {
        case auQuitPre = 1001
        case auCursorMoved = 1002
    }

    func pluginEvent(event id: Int, context: String) -> String? {
        guard let spmEvent = SPMVimEvent(rawValue: id) else {
            return nil
        }
        switch spmEvent {
        case .auQuitPre:
            editorService.process.terminate()
        case .auCursorMoved:
            diagUI.onCursorMoved()
        }
        return nil
    }
}

