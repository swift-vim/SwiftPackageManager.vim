import Foundation

public enum Result <T> {
    case ok(T)
    case failure(Error)

    func toBool() -> Result<Bool> {
        switch self {
        case .ok:
            return .ok(true)
        case .failure(let e):
            return .failure(e)
        }
    }
}

// Thread unsafe value.
public class FutureValue <T> {
    private var value: Result<T>? = nil
    let semaphore = DispatchSemaphore(value: 0)

    public init() {
        self.value = nil
    }

    public func set(_ v: T) {
        if value != nil {
            fatalError("Set value already")
        }
        value = .ok(v)
        semaphore.signal()
    }

    public func set(_ v: Result<T>) {
        if value != nil {
            fatalError("Set value already")
        }
        value = v
        semaphore.signal()
    }

    public func fail(_ e: Error) {
        set(Result.failure(e))
    }

    public func get(timeout: TimeInterval = 0, failure: Result<T> = .failure(ConnectionError.basic("Future did timeout"))) -> Result<T> {
        if value != nil {
            return value!
        }
        let timeout = DispatchTime.now() + .seconds(120)
        if semaphore.wait(timeout: timeout) == .timedOut { // 3
            print("Future did timeout")
            return failure
        } else {
            return value!
        }
    }
}

extension FutureValue {
    func connectFail(_ e: String) {
        fail(ConnectionError.basic(e))
    }
}

public enum ConnectionError : Error {
    case basic(String)

    var localizedDescription: String {
        switch self {
        case .basic(let v):
            return v
        }
    }
}


