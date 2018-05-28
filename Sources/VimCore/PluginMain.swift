import Foundation
import VimInterface

// This is an example of some timer running
// This is mainly added to experiment with pythons main thread
// and will go away.
// https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9
class RepeatingTimer {
    let timeInterval: TimeInterval
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline:.now() + self.timeInterval,
                   repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    var eventHandler: (() -> Void)?
    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .suspended
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}

// Note: that dispatch main doesn't seem to work in the py process
// due to lack of "parking"
class Runner: NSObject {
    let thread = Thread.current
    let rl = RunLoop.current

    @objc
    func run(){
        print("STAT", rl == RunLoop.current)
    }
}

let runner = Runner()
let timer = RepeatingTimer(timeInterval: 1.0)

// Core bootstrap
@_cdecl("plugin_init")
public func plugin_init(){
    timer.eventHandler = {
        runner.perform(#selector(runner.run), with: runner.thread)
    }
    timer.resume()
}
