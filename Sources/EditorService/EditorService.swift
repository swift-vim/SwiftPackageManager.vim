import Foundation
import SKQueue
import SPMProtocol

public struct SwiftBuildDiagnostic {
    public let file: String
    public let line: Int
    public let col: Int
    public let ty: String
    public let message: String

    public static func from(line: String) -> SwiftBuildDiagnostic? {
        let components = line.components(separatedBy: ":")
        guard components.count > 4 else {
            return nil
        }
        let file = components[0]
        let line = Int(components[1]) ?? 0
        let col = Int(components[2]) ?? 0
        let ty = components[3]
        let message = components[3] + ":" + components[4]
        return SwiftBuildDiagnostic(file: file, line: line, col: col, ty: ty, message: message)
    }
}

func getDiagnostic(from buildDiag: SwiftBuildDiagnostic) -> Diagnostic {
    return Diagnostic(text: buildDiag.message,
        fixitAvailable: false,
        isError: true,
        location: Diagnostic.Location(lineNum: buildDiag.line,
            columnNum: buildDiag.col, filepath: buildDiag.file),
        locationExtent: Diagnostic.LocationExtent(
            start: Diagnostic.LocationPoint(lineNum: buildDiag.line,
                columnNum: buildDiag.col),
            end: nil))
}

/// EditorService
/// This is the core plugin backend for SwiftPackageManager.vim
/// Vim Integration
public struct EditorService: SKQueueDelegate {
    let host: String
    let authToken: String
    let path: String

    /// The editor listens to updates in this log
    static let LastBuildLogPath = ".build/last_build.log"

    static let VimQueue = DispatchQueue.init(label: "com.spmvim.es")

    public init(host: String, authToken: String, path: String) {
        self.host = host
        self.authToken = authToken
        self.path = path

        // Periodically, ping the RPCServer to see if its up.
        // if it is not, then assume vim died.
        // There is no other reasonable way to terminate.
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
          _ in
              let method = "status"
              let commandPath = host + "/" + method
              var request = URLRequest(url: URL(string: commandPath)!)
              request.httpMethod = "GET"
              let session = URLSession.shared
              let task = session.dataTask(with: request) {
                  (data, response, error) in
                  if (response as? HTTPURLResponse)?.statusCode != 200 {
                      exit(0)
                  }
              }
              task.resume()
        }
    }

    /// Send a POST request and return the body.
    func post(message commandData: Data, method: String) -> String {
        let commandPath = host + "/" + method
        var request = URLRequest(url: URL(string: commandPath)!)
        request.httpBody = commandData
        request.httpMethod = "POST"
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession.shared
        var responseStr: String?
        let task = session.dataTask(with: request) {
            (data, response, error) in
            if let error = error {
                print("error:", error) 
                responseStr = ""
            } else {
                let decodeData = data ?? Data()
                responseStr = String(data: decodeData, encoding: .utf8) ?? ""
                semaphore.signal()
            }
        }

        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return responseStr ?? ""
    }

    func findPackageRoot(near path: String) -> String? {
        // Search the current path for a "Package.swift"
        let components: [String] = path.components(separatedBy: "/")
        let end = components.endIndex

        // Search sequence from the end of the path to the start
        let seq = components
            .lazy
            .enumerated()
            .map {
                state -> String? in
                let (offset, _) = state
                let range = 0..<end.unsafeSubtracting(offset)
                let maybePath = components[range] + ["Package.swift"]
                let joinedPath = maybePath.joined(separator: "/")
                if FileManager.default.fileExists(atPath: joinedPath) {
                    return components[range].joined(separator: "/")
                }
                return nil
        }
        return seq.first ?? nil ?? nil
    }

    func observeBuildLog(in packagePath: String, queue: SKQueue) {
        let logPath = packagePath +  "/" + EditorService.LastBuildLogPath
        if FileManager.default.fileExists(atPath: logPath) {
            queue.addPath(logPath)
        }
    }

    public func start() {
        // Find the SPMPackage path - search the CWD, then the file in Vim
        // Case 1: the user has cd'd into a SPM dir.
        // Case 2: the user is Vimming a file in some package.
        // Case 2 breaks down when Vimming sub packages.
        let firstPackagePath = findPackageRoot(near: FileManager.default.currentDirectoryPath) 
            ?? findPackageRoot(near: path)
        if let packagePath = firstPackagePath {
            let queue = SKQueue(delegate: self)!
            observeBuildLog(in: packagePath, queue: queue)
        }
        RunLoop.current.run()
    }

    // Mark - SKQueueDelegate

    // Observe for changes in the log file

    public func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
        // This has the effect, that when the log file changes completed,
        // errors are shown in vim. Since this code doesn't understand the
        // notion of a `build` we just naievely update the UI
        print("info: File \(path) had changes \(notification.toStrings().map { $0.rawValue }) ")
        guard let file = try? String(contentsOf: URL(fileURLWithPath: path)) else {
            return
        }

        let diags: [Diagnostic] = file.components(separatedBy: "\n")
            .compactMap { SwiftBuildDiagnostic.from(line: $0) }
            .map { getDiagnostic(from: $0 ) }
        let message = DiagnosticMessage(originFile: path,
            diagnostics: diags)
        guard let encodedData: Data = try? JSONEncoder().encode(message) else {
            return
        }
        _ = post(message: encodedData, method: "diags")
    }
}

