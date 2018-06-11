
struct SignPlacement: Hashable {
    let id: Int
    let line: Int
    let buffer: Int
    let isError: Bool

    public var hashValue: Int {
        return line + buffer + (isError ? 0 : 1)
    }

    public static func ==(lhs: SignPlacement, rhs: SignPlacement) -> Bool {
        return (lhs.line == rhs.line) &&
            (lhs.buffer == rhs.buffer && lhs.isError == rhs.isError)
    }
}

struct DiagnosticViewModel {
    struct Location {
        let lineNum: Int
        let columnNum: Int
        let filepath: String
    }

    struct LocationPoint {
        let lineNum: Int
        let columnNum: Int
    }

    struct LocationExtent {
        let start: LocationPoint
        let end: LocationPoint
    }

    let text: String
    let fixitAvailable: Bool
    let isError: Bool

    let location: Location
    let locationExtent: LocationExtent?
}

typealias BufferInfo = [Int: [Int: [DiagnosticViewModel]]]

class DiagnosticInterface {
    var previousLineNumber = 1
    var nextSignId = 1  
    var placedSigns: [SignPlacement] = []

    var bufferNumberToLineToDiags: BufferInfo  = [:]
    var diagMessageNeedsClearing = false

    public func onCursorMoved() {
        let (line, _) = VimSupport.currentLineAndColumn()
        guard line == previousLineNumber else {
            return
        }
        previousLineNumber = line
        echoDiagnostic(for: line)
    }

    private func echoDiagnostic(for line: Int) {
        let bufferNum = Vim.current.buffer.number
        guard let diags = bufferNumberToLineToDiags[bufferNum]?[line],
            let firstDiag = diags.first else {
                VimSupport.postVimMessage(message: "", warning: false)
                diagMessageNeedsClearing = false
                return
        }

        let text: String
        if firstDiag.fixitAvailable {
            text = firstDiag.text + " (FixIt)"
        } else {
            text = firstDiag.text
        }
        VimSupport.postVimMessage(message: text, warning: false, truncate: true)
        diagMessageNeedsClearing = true
    }

    public func update(diagnostics diags: [DiagnosticViewModel]) {
        // 1) Update the listing of diags in the buffer
        // 2) Update the signs
        // 3) Update Squiggles

        diags.forEach {
            diag -> Void in
            let bufferNum = VimSupport.getBufferNumberForFilename(filename: diag.location.filepath)
            var bufferInfo: [Int: [DiagnosticViewModel]]
            bufferInfo = bufferNumberToLineToDiags[bufferNum] ?? [:]
            var diags = bufferInfo[diag.location.lineNum] ?? []
            diags.append(diag)
            bufferInfo[diag.location.lineNum] = diags
            bufferNumberToLineToDiags[bufferNum] = bufferInfo
            // TODO: errors listed before warnings so errors aren't hidden
        }
        (placedSigns, nextSignId) = UpdateSigns(placedSigns: placedSigns, 
            bufferNumberToLineToDiags: bufferNumberToLineToDiags,
            nextSignId: nextSignId)
        UpdateSquiggles(bufferNumberToLineToDiags: bufferNumberToLineToDiags)
    }
}

func UpdateSigns(placedSigns: [SignPlacement], bufferNumberToLineToDiags: BufferInfo, nextSignId: Int) -> ([SignPlacement], Int) {
    let (newSigns, keptSigns, nextSignId) = GetKeptAndNewSigns(placedSigns: placedSigns, bufferNumberToLineToDiags: bufferNumberToLineToDiags, nextSignId: nextSignId)
    let needsDummy = keptSigns.count == 0 && newSigns.count > 0
    if needsDummy {
       VimSupport.placeDummySign(signId: nextSignId + 1,
          bufferNum: Vim.current.buffer.number,
          lineNum: newSigns[0].line)
    }

    // We use incremental placement, so signs that already placed on the correct
    // lines will not be deleted and placed again, which should improve performance
    // in case of many diags. Signs which don't exist in the current diag should be
    // deleted.
    let newPlaced = PlaceNewSigns(keptSigns: keptSigns,
         newSigns: newSigns)
    UnplaceObseleteSigns(keptSigns: keptSigns,
         newSigns: newSigns)
    if needsDummy {
        VimSupport.unPlaceDummySign(signId: nextSignId + 1,
            bufferNum: Vim.current.buffer.number)
    }
    return (newPlaced, nextSignId)
}

/// Get signs for the visibile buffer
func GetKeptAndNewSigns(placedSigns: [SignPlacement], bufferNumberToLineToDiags: BufferInfo, nextSignId: Int) -> ([SignPlacement], [SignPlacement], Int) {
    let visibleBuffers = Array(bufferNumberToLineToDiags.keys).filter {
        return VimSupport.bufferIsVisible(bufferNumber: $0)
    }
    var oNextSignId = nextSignId
    var keptSings: [SignPlacement] = [] 
    var newSings: [SignPlacement] = [] 
    visibleBuffers.forEach {
        buffNum in
        let bufferInfo = bufferNumberToLineToDiags[buffNum] ?? [:]
        bufferInfo.forEach {
            i in
            let (line, diags) = i
            let firstDiag = diags[0]
            let sign = SignPlacement(id: nextSignId,
                line: line, buffer: buffNum, isError: firstDiag.isError)
            /// Get the previous sign ( this is required to unplace )
            if let existing = placedSigns.first(where: { $0 == sign }) {
                keptSings.append(existing)
            } else {
                newSings.append(sign)
                oNextSignId = oNextSignId + 1
            }
        }
    }

    return (newSings, keptSings, oNextSignId)
}

func PlaceNewSigns(keptSigns: [SignPlacement], newSigns: [SignPlacement]) -> [SignPlacement] {
    return newSigns.flatMap {
        sign in
        if keptSigns.contains(sign) {
            return nil
        }
        VimSupport.placeSign(signId: sign.id, lineNum: sign.line, bufferNum:
            sign.buffer, isError: sign.isError)
        return sign
    }
}

func UnplaceObseleteSigns(keptSigns: [SignPlacement], newSigns: [SignPlacement]) {
    newSigns.forEach {
        sign in 
        if keptSigns.contains(sign) == false {
            return
        }
        VimSupport.unplaceSignInBuffer(bufferNumber: sign.buffer, signId: sign.id)
    }
}

func UpdateSquiggles(bufferNumberToLineToDiags: BufferInfo) {
    VimSupport.clearIcmSyntaxMatches()
    guard let lineDiags = bufferNumberToLineToDiags[Vim.current.buffer.number] else {
        return
    }
    //TODO: Prevent overlapping warnings on errors
    lineDiags.forEach {
        i in
        let (_, diags) = i
        diags.forEach {
            diag in
            _ = VimSupport.addDiagnosticSyntaxMatch(lineNum:
                diag.location.lineNum, columnNum: diag.location.columnNum)
            // TODO: Add the ability to support location extents
        }
    }
}

