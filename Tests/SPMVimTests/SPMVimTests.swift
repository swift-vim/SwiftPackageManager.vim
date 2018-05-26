import XCTest
@testable import SPMVim

class SPMVimTests: XCTestCase {
    static var allTests = [
        ("testErrorExtraction", testErrorExtraction),
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
}
