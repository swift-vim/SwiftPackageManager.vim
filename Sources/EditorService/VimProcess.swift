import Foundation

/// Some Vimmy things for a process
public struct VimProcess {
    public let process: Process
    public let stdoutPipe: Pipe
    public let stderrPipe: Pipe

    public static func with(path: String, args: [String],
                            stdout stdoutHandle: FileHandle? = nil,
                            stderr stderrHandle: FileHandle? = nil) -> VimProcess {

        let process = Process()
        process.launchPath = path
        process.arguments = args

        // Setup a single pipe - don't actually do anything with this
        // for now.
        // Due to some weird issues ( running in Vim ), i/o redirectiona is not
        // currently working 100%
        let pipe = Pipe()
        let stderr = pipe
        let stdout = pipe
        process.standardOutput = pipe
        process.standardError = pipe
        let env = ["LANG": "en_US.UTF-8" ]
        process.environment = env
        return VimProcess(process: process, stdoutPipe: stdout, stderrPipe: stderr)
    }
}

