import VimInterface

// TODO: Rename to VimWindow
public class VimWindow {
    private let value: UnsafeVimValue

    init(value: UnsafeVimValue) {
        self.value = value
    }

    public lazy var cursor: (Int, Int) = {
        guard let cursor = self.value.attrp("cursor") else {
            return (0, 0)
        }
        let first = swiftvim_tuple_get(cursor, 0)
        let second = swiftvim_tuple_get(cursor, 1)
        return (Int(swiftvim_asint(first)), Int(swiftvim_asint(second)))
    }()

    public lazy var height: Int = {
        return self.value.attr("height")
    }()

    public lazy var col: Int = {
        return self.value.attr("col")
    }()

    public lazy var row: Int = {
        return self.value.attr("row")
    }()

    public lazy var valid: Bool = {
        return self.value.attr("valid") != 0
    }()

    public lazy var buffer: VimBuffer = {
        return VimBuffer(value: self.value.attrp("buffer")!)
    }()
}

