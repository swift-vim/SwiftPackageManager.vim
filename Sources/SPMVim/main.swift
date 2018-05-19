import Commandant
import Result

enum BasicError : Error {
  case none
}

struct LogCommand: CommandProtocol {
  typealias Options = LogOptions

  let verb = "log"
  let function = "Reads the log"

  func run(_ options: Options) -> Result<(), BasicError> {
    print("Run")
    return .success(())
  }
}

struct LogOptions: OptionsProtocol {
  let lines: Int
  let verbose: Bool
  let logName: String

  static func create(_ lines: Int) -> (Bool) -> (String) -> LogOptions {
    return { verbose in { logName in LogOptions(lines: lines, verbose: verbose, logName: logName) } }
  }

  static func evaluate(_ m: CommandMode) -> Result<LogOptions, CommandantError<BasicError>> {
    return create
      <*> m <| Option(key: "lines", defaultValue: 0, usage: "the number of lines to read from the logs")
      <*> m <| Option(key: "verbose", defaultValue: false, usage: "show verbose output")
      <*> m <| Argument(usage: "the log to read")
  }
}

let commands = CommandRegistry<BasicError>()
commands.register(LogCommand())

// Commandant Boilderplate
let arguments = CommandLine.arguments
// Remove the executable name.
let verb = arguments.count > 0 ?  arguments[1] : "log"

// Remove the command name.
var margs = arguments
margs.remove(at: 0)
if let result = commands.run(command: verb, arguments: margs) {
  // Handle success or failure.
} else {
  // Unrecognized command.
}

