import SwiftUI
import AppKit

public struct GridSelectorPopoverView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    @State private var hoverRow: Int = 0
    @State private var hoverCol: Int = 0
    @State private var customRows: Int = 2
    @State private var customCols: Int = 2
    
    public init(sessionManager: SessionManager, isPresented: Binding<Bool>) {
        self.sessionManager = sessionManager
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Select Grid Layout")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if hoverRow > 0 && hoverCol > 0 {
                    Text("\(hoverRow) × \(hoverCol)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                } else {
                    Text(sessionManager.activeLayout.displayName)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Interactive 4x4 matrix picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Interactive Matrix")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                VStack(spacing: 4) {
                    ForEach(1...4, id: \.self) { r in
                        HStack(spacing: 4) {
                            ForEach(1...4, id: \.self) { c in
                                let isHighlighted = (r <= hoverRow && c <= hoverCol) ||
                                    (hoverRow == 0 && r <= sessionManager.activeLayout.rows && c <= sessionManager.activeLayout.cols)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        isHighlighted ?
                                        LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 24, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(isHighlighted ? Color.cyan.opacity(0.8) : Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                    .onHover { isHovered in
                                        if isHovered {
                                            hoverRow = r
                                            hoverCol = c
                                        }
                                    }
                                    .onTapGesture {
                                        sessionManager.setLayout(GridLayout(rows: r, cols: c))
                                        isPresented = false
                                    }
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.35))
                .cornerRadius(7)
                .onHover { isHovered in
                    if !isHovered {
                        hoverRow = 0
                        hoverCol = 0
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Standard Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("Standard Presets")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(GridLayout.presets) { preset in
                        Button(action: {
                            sessionManager.setLayout(preset)
                            isPresented = false
                        }) {
                            HStack(spacing: 6) {
                                MiniGridIcon(rows: preset.rows, cols: preset.cols)
                                    .frame(width: 14, height: 12)
                                Text(preset.displayName)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                Spacer()
                                if sessionManager.activeLayout == preset && !sessionManager.isMaximized {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                sessionManager.activeLayout == preset ? Color.cyan.opacity(0.18) : Color.white.opacity(0.05)
                            )
                            .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Custom Rows / Cols Steppers
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Rows & Columns")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(spacing: 12) {
                    Stepper("Rows: \(customRows)", value: $customRows, in: 1...5)
                        .font(.system(size: 11))
                    Stepper("Cols: \(customCols)", value: $customCols, in: 1...5)
                        .font(.system(size: 11))
                }
                
                Button(action: {
                    sessionManager.setLayout(GridLayout(rows: customRows, cols: customCols))
                    isPresented = false
                }) {
                    Text("Apply \(customRows) × \(customCols)")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(Color(nsColor: NSColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1.0)))
        .onAppear {
            customRows = sessionManager.activeLayout.rows
            customCols = sessionManager.activeLayout.cols
        }
    }
}

public struct MiniGridIcon: View {
    let rows: Int
    let cols: Int
    
    public init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let r = max(1, rows)
            let c = max(1, cols)
            let cellW = (w - CGFloat(c - 1) * 1.5) / CGFloat(c)
            let cellH = (h - CGFloat(r - 1) * 1.5) / CGFloat(r)
            
            VStack(spacing: 1.5) {
                ForEach(0..<r, id: \.self) { _ in
                    HStack(spacing: 1.5) {
                        ForEach(0..<c, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primary.opacity(0.75))
                                .frame(width: max(2, cellW), height: max(2, cellH))
                        }
                    }
                }
            }
        }
    }
}

public struct QuickLayoutPillBar: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var showingPopover: Bool
    
    public init(sessionManager: SessionManager, showingPopover: Binding<Bool>) {
        self.sessionManager = sessionManager
        self._showingPopover = showingPopover
    }
    
    private let quickPresets: [GridLayout] = [
        .preset1x1,
        .preset1x2,
        .preset2x2,
        .preset2x3,
        .preset3x3
    ]
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(quickPresets) { preset in
                let isSelected = sessionManager.activeLayout == preset && !sessionManager.isMaximized
                Button(action: {
                    sessionManager.setLayout(preset)
                }) {
                    Text(preset.displayName)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            isSelected ?
                            LinearGradient(colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.clear, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            
            // Popover dropdown trigger for custom/more layouts
            Button(action: {
                showingPopover.toggle()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 10))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
                GridSelectorPopoverView(
                    sessionManager: sessionManager,
                    isPresented: $showingPopover
                )
            }
            .help("More Grid Layouts")
        }
        .padding(3)
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1.0)))
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

public struct FontZoomPillBar: View {
    @ObservedObject var sessionManager: SessionManager
    
    public init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    public var body: some View {
        HStack(spacing: 1) {
            Button(action: {
                sessionManager.zoomOut()
            }) {
                HStack {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.secondary)
                .frame(width: 26, height: 22)
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Zoom Out (⌘-)")
            
            Button(action: {
                sessionManager.resetZoom()
            }) {
                Text("\(Int(sessionManager.globalFontSize))pt")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(height: 22)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.001))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Reset Zoom (⌘0)")
            
            Button(action: {
                sessionManager.zoomIn()
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.secondary)
                .frame(width: 26, height: 22)
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Zoom In (⌘+)")
        }
        .padding(2)
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1.0)))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
