import Commandant
import Result
import LogParser
import Foundation

func getPath(path: String?, relativeTo: String) -> String? {
    if let path = path,
        path.utf8.count > 0 {
        return path.hasSuffix("/") ? path : relativeTo + "/" + path
    }
    return nil
}

enum BasicError : Error {
    case message(String)

    var localizedDescription: String {
        switch self {
        case .message(let value):
            return value
        }
    }
}

struct LogCommand: CommandProtocol {
    typealias Options = LogOptions
    let verb = "log"
    let function = "Reads the log"
    let usage =  """
    Usage:
        cat parseable-build.log | spm-vim log
        or
        spm-vim log parseable-build.log
        To produce a parseable run swift with -parseable-output
    """

    func run(_ options: Options) -> Result<(), BasicError> {
        let assumedDir = FileManager.default.currentDirectoryPath
        let logPath = getPath(path: options.logName, relativeTo: assumedDir)
        // FIXME: is it there a better place to validate?
        if fcntl(FileHandle.standardInput.fileDescriptor, F_GETFL) != 0 
          && logPath == nil {
            return .failure(BasicError.message(usage))
        }
        // TODO: consider how parsing a stream will work. We want
        // the ability to emit warnings as they are encountered.
        let messages = LogParser.readMessages(logPath: logPath)
        messages.forEach {
            message -> Void in
            let out = [
                "message (",
                message.name, ")", 
                " ",
                (message.inputs?.first ?? "")
                ]
            print(out.joined())
        }
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
            <*> m <| Argument(defaultValue: "", usage: "the log to read")
    }
}

struct CompileCommandsCommand: CommandProtocol {
    typealias Options = LogOptions
    let verb = "compile_commands"
    let function = "Generates compile_commands.json"
    let usage = """
    Usage:
        cat parseable-build.log | spm-vim compile_commands
        or
        spm-vim compile_commands parseable-build.log
        To produce a parseable run swift with -parseable-output
    """
    func run(_ options: Options) -> Result<(), BasicError> {
        let assumedDir = FileManager.default.currentDirectoryPath
        let logPath = getPath(path: options.logName, relativeTo: assumedDir)
        // FIXME: is it there a better place to validate?
        if fcntl(FileHandle.standardInput.fileDescriptor, F_GETFL) != 0 
          && logPath == nil {
            return .failure(BasicError.message(usage))
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
            <*> m <| Argument(defaultValue: "", usage: "the log to read")
    }
}

struct EditorServiceCommand: CommandProtocol {
    typealias Options = EditorServiceOptions
    let verb = "editor"
    let function = "Operates the editor"
    let usage =  """
    Usage:
      Core editor service   
    """

    func run(_ options: Options) -> Result<(), BasicError> {
        let host = "http://localhost:" + options.port
        let service = EditorService(host: host, authToken: options.authToken)
        service.start()
        return .success(())
    }
}

struct EditorServiceOptions: OptionsProtocol {
    let authToken: String
    let port: String

    static func create(_ authToken: String) -> (String) -> EditorServiceOptions {
        return { port in
          EditorServiceOptions(authToken: authToken, port: port)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<EditorServiceOptions, CommandantError<BasicError>> {
        return create
            <*> m <| Argument(defaultValue: "", usage: "The auth token for the editor interface")
            <*> m <| Option(key: "port", defaultValue: "0", usage: "port of the editor interface")
    }
}


/// Main
let _ = {
      let commands = CommandRegistry<BasicError>()
      commands.register(LogCommand())
      commands.register(EditorServiceCommand())
      commands.register(CompileCommandsCommand())

      // Commandant Boilderplate
      let arguments = CommandLine.arguments
      guard arguments.count > 1 else {
          let cmdNames = commands.commands.map { $0.verb }
          print("Usage: spm-vim < " + cmdNames.joined(separator: " | ") + " >")
          return 
      }

      let verb = arguments[1]
      // Remove the bin, and command name.
      var margs = arguments
      margs.remove(at: 0)
      margs.remove(at: 0)

      if let result = commands.run(command: verb, arguments: margs) {
          switch result {
          case .success:
              return
          case .failure(let error):
              switch error {
              case .usageError(let description):
                  print(description)
              case .commandError(let clientError):
                  print(clientError.localizedDescription)
              }
          }
      } else {
          print("Unrecognized command")
      }
}()

