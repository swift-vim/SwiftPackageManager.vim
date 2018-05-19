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

var arguments = CommandLine.arguments

// Remove the executable name.
assert(!arguments.isEmpty)
arguments.remove(at: 0)

print("Run")
if let verb = arguments.first {
  // Remove the command name.
  arguments.remove(at: 0)

  if let result = commands.run(command: verb, arguments: arguments) {
    // Handle success or failure.
  } else {
    // Unrecognized command.
  }
} else {
  // No command given.
}

