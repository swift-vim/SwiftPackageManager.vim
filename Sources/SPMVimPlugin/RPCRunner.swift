import Foundation
import HTTP
import VimCore
import EditorService
import SPMProtocol
import Vim

struct VimLogger {
    let fileHandle: FileHandle
    let logFile = "/private/var/tmp/" + UUID().uuidString
    private let loggerQueue = DispatchQueue(label: "com.spmvim.logger")

    init() {
        try? Data().write(to: URL(fileURLWithPath: logFile), options: [.atomic])
        fileHandle = FileHandle(forWritingAtPath: logFile)!
    }

    func log(_ msg: String) {
        loggerQueue.async {    
            guard let data = msg.data(using: .utf8) else {
                return
            }
            self.fileHandle.write(data)
        }
    }
        
    static let shared = VimLogger()
}

protocol RPCObserver {
    func didGet(message: DiagnosticMessage)
}

public struct RPCHandler {
    let observer: RPCObserver

    enum RPCMethod: String {
        case diags = "diags"
    }
  
    func handleDiags(data: Data) {
        let decoder = JSONDecoder()
        if let message = try? decoder.decode(DiagnosticMessage.self, from: data) {
            observer.didGet(message: message)
        } else {
            print("error: invalid request")
        }
    }

    func handleRPC(uri: String, data dData: DispatchData) -> Data {
        // This is kind of hacky:
        // accept urls of the form /method
        VimLogger.shared.log("GotMessage\n")
        guard let data: Data = (((dData as Any) as? NSData) as? Data) else {
            return Data()
        }

        let part = uri.replacingOccurrences(of: "/", with: "")
        guard let method = RPCMethod(rawValue: part) else {
            return Data()
        }
        switch method {
        case .diags:
            VimLogger.shared.log("WillRenderDiags\n")
            VimTask.onMain {
                () -> Void in
                VimLogger.shared.log("RenderOnMain\n")
                self.handleDiags(data: data)
            }
            return Data()
        }
    }

    func handler(request: HTTPRequest, response: HTTPResponseWriter) -> HTTPBodyProcessing {
        response.writeHeader(status: .ok)
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                let result = self.handleRPC(uri: request.target,
data: data)
                response.writeBody(result) { _ in
                    finishedProcessing()
                }
            case .end:
                response.done()
            default:
                stop = true
                response.abort()
            }
        }
    }
}

public struct RPCRunner {
    let task: VimTask<Void>
    let port: FutureValue<Int>
    let handler: RPCHandler
    init(observer: RPCObserver) {
        let port = FutureValue<Int>()
        let handler = RPCHandler(observer: observer)
        self.task = VimTask {
            () -> Void in
            let server = HTTPServer()
            try! server.start(port: 0, handler: handler.handler)
            port.set(.ok(server.port))
            RunLoop.current.run()
        }
        self.handler = handler
        self.port = port
    }

    public func start() {
        task.run()
    }
}

