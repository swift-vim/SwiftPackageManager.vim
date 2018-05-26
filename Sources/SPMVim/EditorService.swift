import Foundation
import SKQueue

/// EditorService
/// This is the core plugin backend for SwiftPackageManager.vim
/// Vim Integration
/// It communicates with Vim via evaling expressions and running commands
/// through the Python Vim API
struct EditorService: SKQueueDelegate {
    let host: String
    let authToken: String

    /// The editor listens to updates in this log
    static let LastBuildLogPath = ".build/last_build.log"

    /// vim.command
    func vimCommand(command: String) -> String {
        return post(str: command, method: "c")
    }

    /// vim.eval
    func vimEval(eval: String) -> String {
        return post(str: eval, method: "e")
    }

    /// Send a POST request and return the body.
    func post(str: String, method: String) -> String {
        let commandPath = host + "/" + method
        let commandData = str.data(using:.ascii)!
        var request = URLRequest(url: URL(string: commandPath)!)
        request.httpBody = commandData
        request.httpMethod = "POST"
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession.shared
        var responseStr: String!
        let task = session.dataTask(with: request) {
            (data, response, error) in
            if let error = error {
                print("error:", error) 
                responseStr = ""
            } else {
                let decodeData = data ?? Data()
                responseStr = String(data: decodeData, encoding: .ascii) ?? ""
                semaphore.signal()
            }
        }

        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return responseStr
    }


    func start() {
        // Post a message for testing
        _ = vimCommand(command: "echom 'warning: started experimental spm-vim plugin'")

        // Setup observation for a path
        let path = vimEval(eval: "expand('%:p')")

        // Search the current path for a "Package.swift"
        // assume that the build we are watching is in there.
        let components: [String] = path.components(separatedBy: "/")
        let packagePath = components.reduce([String]()) {
            accum, x in
            if accum.last == "Package.swift" {
                return accum
            }

            if accum.count == 0 {
                return [x]
            }
            let maybePath = accum + ["Package.swift"]
            if FileManager.default.fileExists(atPath: maybePath.joined(separator: "/")) {
                return maybePath
            }
            return accum + [x]
        }

        var guessedLogDir = packagePath
        guessedLogDir[packagePath.count - 1] = EditorService.LastBuildLogPath
        let logPath = guessedLogDir.joined(separator: "/")

        let queue = SKQueue(delegate: self)!
        queue.addPath(logPath)
        CFRunLoopRun()
    }

    // Mark - SKQueueDelegate

    // Observe for changes in the log file

    func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
        // This has the effect, that when builds are completed, the
        // quickfix list gets updated
        _ = vimCommand(command: "call spm#showerrfile('\(path)')")
    }
}


