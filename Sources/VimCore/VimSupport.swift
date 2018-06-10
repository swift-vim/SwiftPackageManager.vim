import Foundation

/// Turn a value into a vimscript
public protocol VimScriptConvertible {
    func toVimScript() -> String
}

extension Int: VimScriptConvertible{
    public func toVimScript() -> String {
        return String(self)
    }
}

extension String: VimScriptConvertible {
    public func toVimScript() -> String {
        return self
    }
}

struct VimSupport {
    public static func escapeForVim(_ value: String) -> String {
        return toUnicode(value).replacingOccurrences(of: "'", with: "''")
    }

    public static func toUnicode(_ value: String) -> String {
        //TODO
        return value
    }

    /// Mark - Eval Helpers
    public static func variableExists(_ variable: String) -> Bool {
        return getBoolValue("exists('\(escapeForVim(variable))'")
    }

    public static func set(variable: String, value: VimScriptConvertible) {
        Vim.command("let \(variable) = \(value.toVimScript())")
    }

    public static func getVariableValue(_ variable: String) -> VimValue {
        return Vim.eval(variable)
    }

    public static func getBoolValue(_ variable: String) -> Bool {
        return Bool((Vim.eval(variable).asInt() ?? 0) != 0)
    }

    public static func getIntValue(_ variable: String) -> Int {
        return Vim.eval(variable).asInt() ?? 0
    }

    /// Returns the 0-based current line and 0-based current column
    public static func currentLineAndColumn() -> (Int, Int) {
        return Vim.current.window.cursor
    } 

    // FIXME: this is not 100%
    // It doesn't handle cases like /tmp/
    public static func realpath(_ path: String) -> String {
        return URL(fileURLWithPath: path)
            .standardizedFileURL.resolvingSymlinksInPath().path
    }

    // MARK - Buffers

    public static func getBufferNumberForFilename(filename: String, openFileIfNeeded: Bool=false) -> Int {
        let path = escapeForVim(realpath(filename))
        let create = openFileIfNeeded == true ? "1" : "0"
        return getIntValue("bufnr('\(path)', \(create))")
    }

    public static func bufferIsVisible(bufferNumber: Int) -> Bool {
        guard bufferNumber > 0 else {
            return false
        }
        let windowNumber = getIntValue("bufwinnr(\(bufferNumber))")
        return windowNumber != -1
    }
}

// MARK - Diagnostics

extension VimSupport {
    public static func placeSign(signId: Int, lineNum: Int, bufferNum: Int, isError: Bool=true) {
        var mLineNum = lineNum
        if lineNum < 1 {
            mLineNum = 1
        }
        let signName = isError ? "IcmError" : "IcmWarning"
        Vim.command(
            "sign place \(signId) name=\(signName) line=\(mLineNum) buffer=\(bufferNum)")
    }

    public static func placeDummySign(signId: Int, bufferNum: Int, lineNum: Int) {
        if bufferNum < 0 || lineNum < 0 {
            return
        }
        Vim.command("sign define icm_dummy_sign")
        Vim.command(
            "sign place \(signId) name=icm_dummy_sign line=\(lineNum) buffer=\(bufferNum)")
    }

    public static func unplaceSignInBuffer(bufferNumber: Int, signId: Int) {
        if bufferNumber < 0 {
            return
        }
        Vim.command(
            "try | exec 'sign unplace \(signId) buffer=\(bufferNumber)' | catch /E158/ | endtry")
    }

    public static func unPlaceDummySign(signId: Int, bufferNum: Int) {
        if bufferNum < 0 {
            return
        }
        Vim.command("sign undefine icm_dummy_sign")
        Vim.command("sign unplace \(signId) buffer=\(bufferNum)")
    }
}


extension VimSupport {
    /// Highlight a range in the current window starting from
    /// (|lineNum|, |columnNum|) included to (|lineEndNum|, |columnEndNum|)
    /// excluded.
    /// If |lineEndNum| or |columnEndNum| are not given, highlight the
    /// character at (|lineNum|, |columnNum|). Both line and column numbers are
    /// 1-based. Return the ID of the newly added match.
    public static func addDiagnosticSyntaxMatch(lineNum: Int,
                                 columnNum: Int,
                                 lineEndNum: Int?=nil,
                                 columnEndNum: Int?=nil,
                                 isError: Bool=true) -> Int {
        let group = isError ? "IcmErrorSection" : "IcmWarningSection"

        let (lineNum, columnNum) = lineAndColumnNumbersClamped(lineNum: lineNum, columnNum: columnNum)
        if lineEndNum == nil || columnEndNum == nil {
            return getIntValue(
                "matchadd('\(group)', '%\(lineNum)%{\(columnNum)c')")
        }
        // -1 and then +1 to account for column end not included in the range.
        var (lineEndNum, columnEndNum) = lineAndColumnNumbersClamped(
            lineNum: lineEndNum, columnNum: (columnEndNum ?? 0) - 1)
        columnEndNum += 1

        return getIntValue(
            "matchadd('\(group)', '%\(lineNum)l%\(columnNum)c_.\\{{-}}%\(lineEndNum)l%\(columnEndNum)c')")
    }

    /// Clamps the line and column numbers so that they are not past the contents of
    /// the buffer. Numbers are 1-based byte offsets.
    public static func lineAndColumnNumbersClamped(lineNum: Int?, columnNum: Int?) -> (Int, Int) {
        var newLineNum = lineNum ?? 0
        var newColumnNum = columnNum ?? 0

        let blist = Vim.current.buffer.asList()
        let maxLine = blist.count
        if lineNum != nil && newLineNum > maxLine {
            newLineNum = maxLine
        }
        let maxColumn = blist[newLineNum - 1].asString()!.utf8.count
        if columnNum != nil && newColumnNum > maxColumn {
            newColumnNum = maxColumn
        }
        return (newLineNum, newColumnNum)
    }

    /// Display a message on the Vim status line. By public static funcault, the message is
    /// highlighted and logged to Vim command-line history (see :h history).
    /// Unset the |warning| parameter to disable this behavior. Set the |truncate|
    /// parameter to avoid hit-enter prompts (see :h hit-enter) when the message is
    /// longer than the window width
    public static func postVimMessage(message: String, warning: Bool=true, truncate: Bool=false) {
        let echoCommand = warning ? "echom" : "echo"
        // Displaying a new message while previous ones are still on the status line
        // might lead to a hit-enter prompt or the message appearing without a
        // newline so we do a redraw first.
        Vim.command("redraw")

        if warning {
            Vim.command("echohl WarningMsg")
        }
        let message = toUnicode(message)
        if truncate {
            let vimWidth = getIntValue("&columns")

            var message = message.replacingOccurrences(of: "\n", with:" ")
            // FIXME: char count and truncation
            if message.utf8.count > vimWidth {
                /// message = message[: vimWidth - 4] + "..."
            }

            let oldRuler = getIntValue("&ruler")
            let oldShowcmd = getIntValue("&showcmd")
            Vim.command("set noruler noshowcmd")

            Vim.command("\(echoCommand) \(escapeForVim(message))")

            set(variable: "&ruler", value: oldRuler)
            set(variable: "&showcmd", value: oldShowcmd)
        } else {
            for line in message.components(separatedBy: "\n") {
                Vim.command("\(echoCommand) \(escapeForVim(line))")
            }
        }
        if warning {
            Vim.command("echohl None")
        }
    }

    public static func clearIcmSyntaxMatches() {
        guard let matches = Vim.command("getmatches()").asList() else {
            return
        }
        for matchValue in matches {
            if let match = matchValue.asDictionary(),
                 match["group"]?.asString()?.hasPrefix("Icm") == true {
                Vim.eval("matchdelete(\(match["id"]!))")
            }
        }
    }
}

