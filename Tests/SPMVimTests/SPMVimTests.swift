import XCTest
@testable import EditorService
import VimCore

class SPMVimTests: XCTestCase {
    static var allTests = [
        ("testErrorExtraction", testErrorExtraction),
        ("testProcess", testProcess),
    ]

    // FIXME: Move editor service into a testable lib
    func testErrorExtraction() {
        let line = "/SwiftPackageManager.vim/Sources/SPMVim/main.swift:6:1: error: use of unresolved identifier 'a'nan^n"

        // let pattern = "(.*)\\+:(\\d\\+):(\\d\\+):\\s*error:\\s*\\(.*\\)$"
        // FIXME: handle errors of arbitrary len
        let err = SwiftBuildError.from(line: line)!
        XCTAssertEqual(err.file, "/SwiftPackageManager.vim/Sources/SPMVim/main.swift")
        XCTAssertEqual(err.line, 6)
        XCTAssertEqual(err.col, 1)
        XCTAssertEqual(err.ty, " error")
        XCTAssertEqual(err.message, " error: use of unresolved identifier 'a'nan^n")
    }

    //TODO: Move this over to VimCore
    func testProcess() {
        let process = VimProcess.with(path: "/bin/bash",
                   args: ["-c", "/bin/ls 2>&1 | cat > /tmp/x"])
        process.process.launch()
        process.process.waitUntilExit()
        XCTAssertEqual(process.process.terminationStatus, 0)
    }
}
