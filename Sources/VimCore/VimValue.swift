import Foundation
import VimInterface

public struct VimDictionary {
    private let value: UnsafeMutableRawPointer

    fileprivate init(value: UnsafeMutableRawPointer) {
        self.value = value
    }

    public var count: Int {
        return Int(swiftvim_dict_size(value))
    }

    public var keys: VimList {
        return VimValue(value: swiftvim_dict_keys(value),
                  doDeInit: true).asList()!
    }

    public var values: VimList {
        return VimValue(value: swiftvim_dict_values(value),
                  doDeInit: true).asList()!
    }

    public subscript(index: VimValue) -> VimValue? {
        get {
            guard let v = swiftvim_dict_get(value, index.value) else {
                return nil
            }
            return VimValue(value: v)
        }
        set {
            swiftvim_dict_set(value, index.value, newValue?.value)
        }
    }

    public subscript(index: String) -> VimValue? {
        get {
            return index.withCString { cStrIdx in
                guard let v = swiftvim_dict_getstr(value, cStrIdx) else {
                    return nil
                }
                return VimValue(value: v)
            }
        }
        set {
            index.withCString { cStrIdx in
                swiftvim_dict_setstr(value, cStrIdx, newValue?.value)
            }
        }
    }
}


/// A List of VimValues
public struct VimList: Collection {
    private let value: UnsafeMutableRawPointer

    /// Cast a VimValue to a VimList
    public init(_ vimValue: VimValue) {
        self.value = vimValue.value
    }

    fileprivate init(value: UnsafeMutableRawPointer) {
        self.value = value
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return Int(swiftvim_list_size(value))
    }

    public var isEmpty: Bool {
        return swiftvim_list_size(value) == 0 
    }

    public var count: Int {
        return Int(swiftvim_list_size(value))
    }

    public subscript(index: Int) -> VimValue {
        get {
            return VimValue(value: swiftvim_list_get(value, Int32(index)))
        }
        set {
            swiftvim_list_set(value, Int32(index), newValue.value)
        }
    }

    public func index(after i: Int) -> Int {
        precondition(i < endIndex, "Can't advance beyond endIndex")
        return i + 1
    }
}

/// Vim Value represents a value in Vim
public class VimValue {
    fileprivate let value: UnsafeMutableRawPointer
    private let doDeInit: Bool

    fileprivate init(value: UnsafeMutableRawPointer,
                     doDeInit: Bool = false) {
        self.value = value
        self.doDeInit = doDeInit
    }

    deinit {
        /// Correctly decrement when this value is done.
        if doDeInit {
            swiftvim_decref(value)
        }
    }

    // Mark - Casting

    func asString() -> String? {
        guard let cStr = swiftvim_asstring(value) else {
            return nil
        }
        return String(cString: cStr)
    }

    func asInt() -> Int? {
        return Int(swiftvim_asint(value))
    }

    func asList() -> VimList? {
        return VimList(value: value)
    }

    func asDictionary() -> VimDictionary? {
        return VimDictionary(value: value)
    }
}

/// Mark - Vim Interface

public struct Vim {

    /// Run a vim command
    public static func command(_ cmd: String) -> VimValue {
        var value: VimValue!
        cmd.withCString { cStr in
            // This command returns a None
            let result = swiftvim_command(
              UnsafeMutablePointer(mutating: cStr))
            value = VimValue(value: result!)
        }
        return value
    }

    /// Run a vim command
    public static func eval(_ cmd: String) -> VimValue {
        var value: VimValue!
        cmd.withCString { cStr in
            // This eval returns a None
            let result = swiftvim_eval(
              UnsafeMutablePointer(mutating: cStr))
            value = VimValue(value: result!)
        }
        return value
    }

}

