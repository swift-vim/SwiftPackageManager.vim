
public struct Diagnostic: Codable {
    public struct Location: Codable {
        public let lineNum: Int
        public let columnNum: Int
        public let filepath: String

        public init(lineNum: Int, columnNum: Int, filepath: String) {
            self.lineNum = lineNum
            self.columnNum = columnNum
            self.filepath = filepath
        }
    }

    public struct LocationPoint: Codable {
        public let lineNum: Int
        public let columnNum: Int
        public init(lineNum: Int, columnNum: Int) {
            self.lineNum = lineNum
            self.columnNum = columnNum
        }
    }

    public struct LocationExtent: Codable  {
        public let start: LocationPoint
        public let end: LocationPoint?

        public init(start: LocationPoint, end: LocationPoint?) {
            self.start = start
            self.end = end
        }
    }

    public let text: String
    public let fixitAvailable: Bool
    public let isError: Bool

    public let location: Location
    public let locationExtent: LocationExtent?

    public init(text: String, fixitAvailable: Bool, isError: Bool, location:
        Location, locationExtent: LocationExtent) {
        self.text = text
        self.isError = isError
        self.fixitAvailable = fixitAvailable
        self.location = location
        self.locationExtent = locationExtent
    }
}

// Message that diagnostics are available.
public struct DiagnosticMessage: Codable {
    public let originFile: String?
    public let diagnostics: [Diagnostic]
    public init(originFile: String?,
                diagnostics: [Diagnostic]) {
        self.originFile = originFile
        self.diagnostics = diagnostics
    }
}

