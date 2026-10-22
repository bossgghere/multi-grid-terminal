import Foundation

public enum LayoutKind: String, Hashable, Sendable {
    case standardGrid       // Standard rows x cols
    case oneLeftTwoRight    // 1 Left half full-height, 2 Right (Top & Bottom)
    case twoLeftOneRight    // 2 Left (Top & Bottom), 1 Right half full-height
    case oneTopTwoBottom    // 1 Top half full-width, 2 Bottom (Left & Right)
}

public struct GridLayout: Hashable, Identifiable, Sendable {
    public let kind: LayoutKind
    public let rows: Int
    public let cols: Int
    public let customDisplayName: String?
    
    public var id: String {
        switch kind {
        case .standardGrid:
            return "\(rows)x\(cols)"
        case .oneLeftTwoRight:
            return "1L_2R"
        case .twoLeftOneRight:
            return "2L_1R"
        case .oneTopTwoBottom:
            return "1T_2B"
        }
    }
    
    public var count: Int {
        switch kind {
        case .standardGrid:
            return rows * cols
        case .oneLeftTwoRight, .twoLeftOneRight, .oneTopTwoBottom:
            return 3
        }
    }
    
    public var displayName: String {
        if let name = customDisplayName { return name }
        switch kind {
        case .standardGrid:
            return "\(rows) × \(cols)"
        case .oneLeftTwoRight:
            return "1 Left + 2 Right"
        case .twoLeftOneRight:
            return "2 Left + 1 Right"
        case .oneTopTwoBottom:
            return "1 Top + 2 Bottom"
        }
    }
    
    public init(rows: Int, cols: Int, displayName: String? = nil) {
        self.kind = .standardGrid
        self.rows = max(1, min(rows, 6))
        self.cols = max(1, min(cols, 6))
        self.customDisplayName = displayName
    }
    
    public init(kind: LayoutKind, displayName: String? = nil) {
        self.kind = kind
        self.rows = 2
        self.cols = 2
        self.customDisplayName = displayName
    }
    
    public static let preset1x1 = GridLayout(rows: 1, cols: 1)
    public static let preset1x2 = GridLayout(rows: 1, cols: 2)
    public static let preset2x1 = GridLayout(rows: 2, cols: 1)
    public static let preset1Left2Right = GridLayout(kind: .oneLeftTwoRight, displayName: "3 Split (1L + 2R)")
    public static let preset2Left1Right = GridLayout(kind: .twoLeftOneRight, displayName: "3 Split (2L + 1R)")
    public static let preset1Top2Bottom = GridLayout(kind: .oneTopTwoBottom, displayName: "3 Split (1T + 2B)")
    public static let preset2x2 = GridLayout(rows: 2, cols: 2)
    public static let preset2x3 = GridLayout(rows: 2, cols: 3)
    public static let preset2x4 = GridLayout(rows: 2, cols: 4)
    public static let preset3x3 = GridLayout(rows: 3, cols: 3)
    
    public static let presets: [GridLayout] = [
        preset1x1,
        preset1x2,
        preset1Left2Right,
        preset2x1,
        preset2x2,
        preset2x3,
        preset2x4,
        preset3x3,
    ]
}
