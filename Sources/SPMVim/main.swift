import Commandant
import Result
import LogParser
import Foundation

func getPath(path: String, relativeTo: String) -> String {
    return path.hasSuffix("/") ?
        path : relativeTo + "/" + path
}

enum BasicError : Error {
  case none
}

struct LogCommand: CommandProtocol {
    typealias Options = LogOptions

    let verb = "log"
    let function = "Reads the log"

    func run(_ options: Options) -> Result<(), BasicError> {
        let assumedDir = FileManager.default.currentDirectoryPath
        var logPath: String?
        if let logName = options.logName { 
            logPath =  getPath(path: logName, relativeTo: assumedDir)
        }

        if fcntl(FileHandle.standardInput.fileDescriptor, F_GETFL) != 0 
          && logPath == nil {
            print("""
            Usage:
                cat parseable-build.log | spm-vim log
                or
                spm-vim log parseable-build.log
                To produce a parseable run swift with -parseable-output
            """)
            // FIXME
            return .success(())
        }
        let messages = LogParser.readMessages(logPath: logPath)
        let db = LogParser.renderCompileCommands(messages: messages, dir:
            assumedDir)
        let outFile = URL(fileURLWithPath: assumedDir + "/compile_commands.json")
        try? db.write(to: outFile, atomically: false, encoding: .utf8)
        return .success(())
    }
}

struct LogOptions: OptionsProtocol {
  let logName: String?

  static func create(_ logName: String?) -> LogOptions {
    return LogOptions(logName: logName)
  }

  static func evaluate(_ m: CommandMode) -> Result<LogOptions, CommandantError<BasicError>> {
    return create
      <*> m <| Argument(usage: "the log to read")
  }
}

struct CompileCommandsCommand: CommandProtocol {
    typealias Options = LogOptions
    let verb = "compile_commands"
    let function = "Generates compile_commands.json"

    func run(_ options: Options) -> Result<(), BasicError> {
        let assumedDir = FileManager.default.currentDirectoryPath
        var logPath: String?
        if let logName = options.logName { 
            logPath =  getPath(path: logName, relativeTo: assumedDir)
        }
        if fcntl(FileHandle.standardInput.fileDescriptor, F_GETFL) != 0 
          && logPath == nil {
            print("""
            Usage:
                cat parseable-build.log | spm-vim log
                or
                spm-vim log parseable-build.log
                To produce a parseable run swift with -parseable-output
            """)
            // FIXME
            return .success(())
        }
        let messages = LogParser.readMessages(logPath: logPath)
        let db = LogParser.renderCompileCommands(messages: messages, dir:
            assumedDir)
        let outFile = URL(fileURLWithPath: assumedDir + "/compile_commands.json")
        try? db.write(to: outFile, atomically: false, encoding: .utf8)
        return .success(())
    }
}

struct CompileCommandsOptions: OptionsProtocol {
  let logName: String?

  static func create(_ logName: String?) -> CompileCommandsOptions {
    return CompileCommandsOptions(logName: logName)
  }

  static func evaluate(_ m: CommandMode) -> Result<CompileCommandsOptions, CommandantError<BasicError>> {
    return create
      <*> m <| Argument(usage: "the log to read")
  }
}

let commands = CommandRegistry<BasicError>()
commands.register(LogCommand())
commands.register(CompileCommandsCommand())

// Commandant Boilderplate
let arguments = CommandLine.arguments
// Remove the executable name.
let verb = arguments.count > 0 ?  arguments[1] : "log"

// Remove the command name.
var margs = arguments
margs.remove(at: 0)
do {
  if let _ = commands.run(command: verb, arguments: margs) {
  } else {
    print("Unrecognized command")
  } 
} catch {
  print("Error", error)
}

