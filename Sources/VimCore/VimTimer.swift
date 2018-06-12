import Foundation

// Basic Dispatch Timer for Vim
// Originally inspired by this
// https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9
public final class VimTimer {
    let timeInterval: TimeInterval
    private var eventHandler: (() -> Void)?

    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline:.now() + self.timeInterval,
                   repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    public init(timeInterval: TimeInterval, eventHandler: @escaping (() -> Void)) {
        self.timeInterval = timeInterval
        self.eventHandler = eventHandler
    }

    public func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    public func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}

