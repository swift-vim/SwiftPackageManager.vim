import Foundation

/// Create tasks for new threads or use existing ones
/// The program should be as synchronous as possible
public final class VimTask<T> : NSObject {
    public typealias VimTaskBlock = () -> T

    init (on thread: Thread? = nil, bl: @escaping VimTaskBlock) {
        self.bl = bl
        self.thread = thread
        super.init()
    }

    /// Execute a block on Vim's main thread
    public static func onMain(_ bl: @escaping VimTaskBlock) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var data: T!
        let t = VimTask(on: Thread.main) {
            data = bl()
            semaphore.signal()
            return data
        }
        t.run()
        semaphore.wait()
        return data
    }

    var isDone: Bool {
        var x = false
        mutQueue.sync {
            x = self.done
        }
        return x
    }

    public func run() {
        if let thread = self.thread {
            self.perform(#selector(start), with: thread)
        } else {
            Thread.detachNewThreadSelector(#selector(start), toTarget:self, with: nil) 
        }
    }

    private let bl: VimTaskBlock
    private let thread: Thread?
    private let mutQueue = DispatchQueue(label: "com.bs.threadMut")
    private var done = false
    private var running = false

    @objc
    private func start(sender: Any!) {
        mutQueue.sync {
            self.running = true
        }
        let _ = bl()
        mutQueue.sync {
            self.done = true
            self.running = false
        }
    }
}

