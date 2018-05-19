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
  let logName: String?

  static func create(_ logName: String?) -> LogOptions {
    return LogOptions(logName: logName)
  }

  static func evaluate(_ m: CommandMode) -> Result<LogOptions, CommandantError<BasicError>> {
    return create
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
do {
  if let result = commands.run(command: verb, arguments: margs) {
    // Handle success or failure.
  } else {
    print("Unrecognized command")
  } 
} catch {
  print("Error", error)
}

