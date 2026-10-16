import Foundation

public struct GridLayout: Hashable, Identifiable, Sendable {
    public let rows: Int
    public let cols: Int
    
    public var id: String { "\(rows)x\(cols)" }
    public var count: Int { rows * cols }
    public var displayName: String { "\(rows) × \(cols)" }
    
    public init(rows: Int, cols: Int) {
        self.rows = max(1, min(rows, 6))
        self.cols = max(1, min(cols, 6))
    }
    
    public static let preset1x1 = GridLayout(rows: 1, cols: 1)
    public static let preset1x2 = GridLayout(rows: 1, cols: 2)
    public static let preset2x1 = GridLayout(rows: 2, cols: 1)
    public static let preset2x2 = GridLayout(rows: 2, cols: 2)
    public static let preset2x3 = GridLayout(rows: 2, cols: 3)
    public static let preset2x4 = GridLayout(rows: 2, cols: 4)
    public static let preset3x3 = GridLayout(rows: 3, cols: 3)
    
    public static let presets: [GridLayout] = [
        preset1x1,
        preset1x2,
        preset2x1,
        preset2x2,
        preset2x3,
        preset2x4,
        preset3x3,
    ]
}
