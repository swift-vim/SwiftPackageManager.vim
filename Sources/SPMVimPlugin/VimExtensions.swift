import SPMVimPluginVim

extension Vim {
    /// In several cases, there is nothing actionable
    public static func commandCatching(_ cmd: String) {
        do {
            try command(cmd)
        } catch { }
    }

    public static func placeSign(in bufferNum: Int, signId: Int, lineNum: Int,  isError: Bool=true) {
        var mLineNum = lineNum
        if lineNum < 1 {
            mLineNum = 1
        }
        let signName = isError ? "IcmError" : "IcmWarning"
        commandCatching(
            "sign place \(signId) name=\(signName) line=\(mLineNum) buffer=\(bufferNum)")
    }

    public static func placeDummySign(in bufferNum: Int, signId: Int, lineNum: Int) {
        if bufferNum < 0 || lineNum < 0 {
            return
        }
        commandCatching("sign define icm_dummy_sign")
        commandCatching(
            "sign place \(signId) name=icm_dummy_sign line=\(lineNum) buffer=\(bufferNum)")
    }

    public static func unplaceSign(in bufferNum: Int, signId: Int) {
        if bufferNum < 0 {
            return
        }
        commandCatching(
            "try | exec 'sign unplace \(signId) buffer=\(bufferNum)' | catch /E158/ | endtry")
    }

    public static func unPlaceDummySign(in bufferNum: Int, signId: Int) {
        if bufferNum < 0 {
            return
        }
        commandCatching("try | exec 'sign undefine icm_dummy_sign' | catch /E155/ | endtry")
        commandCatching("sign unplace \(signId) buffer=\(bufferNum)")
    }
}

extension Vim {
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
            return get(
                "matchadd('\(group)', '\\%\(lineNum)l\\%\(columnNum)c')")
        }
        // -1 and then +1 to account for column end not included in the range.
        var (lineEndNum, columnEndNum) = lineAndColumnNumbersClamped(
            lineNum: lineEndNum, columnNum: (columnEndNum ?? 0) - 1)
        columnEndNum += 1
        return get(
            "matchadd('\(group)', '%\(lineNum)l%\(columnNum)c_.\\{{-}}%\(lineEndNum)l%\(columnEndNum)c')")
    }

    /// Clamps the line and column numbers so that they are not past the contents of
    /// the buffer. Numbers are 1-based byte offsets.
    public static func lineAndColumnNumbersClamped(lineNum: Int?, columnNum: Int?) -> (Int, Int) {
        var newLineNum = lineNum ?? 0
        var newColumnNum = columnNum ?? 0

        let blist = current.buffer.asList()
        let maxLine = blist.count
        if lineNum != nil && newLineNum > maxLine {
            newLineNum = maxLine
        }
        let maxColumn = String(blist[newLineNum - 1])?.utf8.count ?? 0
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
        commandCatching("redraw")

        if warning {
            commandCatching("echohl WarningMsg")
        }
        if truncate {
            let vimWidth: Int = get("&columns")

            var message = message.replacingOccurrences(of: "\n", with:" ")
            // FIXME: char count and truncation
            if message.utf8.count > vimWidth {
                /// message = message[: vimWidth - 4] + "..."
            }

            let oldRuler: Int = get("&ruler")
            let oldShowcmd: Int = get("&showcmd")
            commandCatching("set noruler noshowcmd")

            commandCatching("\(echoCommand) '\(escapeForVim(message))'")

            set(variable: "&ruler", value: oldRuler)
            set(variable: "&showcmd", value: oldShowcmd)
        } else {
            for line in message.components(separatedBy: "\n") {
                commandCatching("\(echoCommand) '\(escapeForVim(line))'")
            }
        }
        if warning {
            commandCatching("echohl None")
        }
    }

    public static func clearIcmSyntaxMatches() {
        guard let value = try? eval("getmatches()"),
            let matches = VimList(value) else {
            return
        }
        // FIXME: Check types
        for matchValue in matches {
            if let match = VimDictionary(matchValue),
                String(match["group"])?.hasPrefix("Icm") == true,
                let id = Int(match["id"]) {
                _ = try? eval("matchdelete(\(id))")
            }
        }
    }
}
