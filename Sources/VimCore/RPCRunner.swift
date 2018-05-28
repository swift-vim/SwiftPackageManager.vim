import Foundation
import HTTP
import VimInterface

/// Mark - Protocol

/// Currently, it supports command and eval
/// 
/// Note: we send all data back over the wire in the form
/// of a string.
///
/// Eventually, the protocol should encode correct data types.
/// This is mainly useful to notifiy the UI when data has updated
/// So the treatment of return values is mostly optional.

enum RPCMethod: String {
    case command = "c"
    case eval = "e"
}

/// Run a vim eval and send it back over the wire

func vimEval(text: String) -> Data {
    var data: Data!
    _ = text.withCString {
        cStr -> Void in
        let result = swiftvim_eval(
            UnsafeMutablePointer(mutating: cStr))
        let asStr = swiftvim_asstring(result)
        if let str = asStr {
            let value = String(cString: str)
            data = value.data(using: .utf8)
        } else {
            data = Data()
        }
    }
    return data
}

func vimCommand(text: String) -> Data {
    var data: Data!
    _ = text.withCString {
        cStr -> Void in
        let result = swiftvim_command(
            UnsafeMutablePointer(mutating: cStr))
        let asStr = swiftvim_asstring(result)
        if let str = asStr {
            let value = String(cString: str)
            data = value.data(using: .utf8)
        } else {
            data = Data()
        }
    }
    return data
}

func invokeVimForURI(uri: String, data dData: DispatchData) -> Data {
    // This is kind of hacky:
    // accept urls of the form /method
    guard let data: Data = (((dData as Any) as? NSData) as? Data) else {
        return Data()
    }

    let part = uri.replacingOccurrences(of: "/", with: "")
    guard let method = RPCMethod(rawValue: part) else {
        return Data()
    }
    guard let body = String(data: data, encoding: .utf8) else {
        return Data()
    }

    switch method {
    case .command:
        return VimTask.onMain { vimCommand(text: body) }
    case .eval:
        return VimTask.onMain { vimEval(text: body) }
    }
}

func handler(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
    response.writeHeader(status: .ok)
    return .processBody { (chunk, stop) in
        switch chunk {
        case .chunk(let data, let finishedProcessing):
            let result = invokeVimForURI(uri: request.target,
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

public struct RPCRunner {
    let task: VimTask<Void>
    let port: FutureValue<Int>

    public init() {
        let port = FutureValue<Int>()
        self.task = VimTask {
            let server = HTTPServer()
            try! server.start(port: 0, handler: handler)
            port.set(.ok(server.port))
            RunLoop.current.run()
        }
        self.port = port
    }

    public func start() {
        task.run()
    }
}

