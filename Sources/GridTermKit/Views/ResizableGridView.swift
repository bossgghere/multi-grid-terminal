import SwiftUI
import AppKit

public struct ResizableGridView: View {
    @ObservedObject var sessionManager: SessionManager
    
    @State private var colWeights: [CGFloat] = []
    @State private var rowWeights: [CGFloat] = []
    @State private var lastLayoutId: String = ""
    @State private var splitRatio: CGFloat = 0.5
    @State private var subSplitRatio: CGFloat = 0.5
    
    public init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    private var rows: Int { sessionManager.activeLayout.rows }
    private var cols: Int { sessionManager.activeLayout.cols }
    private let dividerSize: CGFloat = 4.0
    
    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            
            if sessionManager.isMaximized, let active = sessionManager.activeSession {
                // Maximized single pane
                TerminalPaneView(
                    session: active,
                    isFocused: true,
                    shortcutIndex: active.sessionNumber,
                    onFocus: { sessionManager.setActiveSession(active) },
                    onMaximize: { sessionManager.toggleMaximize(for: active) },
                    onClose: { sessionManager.closeSession(active) },
                    onRestart: { sessionManager.restartSession(active) },
                    onClear: { active.clear() }
                )
                .padding(4)
            } else {
                switch sessionManager.activeLayout.kind {
                case .oneLeftTwoRight:
                    renderOneLeftTwoRight(width: max(10, totalWidth - 8), height: max(10, totalHeight - 8))
                        .padding(4)
                        .onChange(of: sessionManager.activeLayout.id) { _, _ in
                            splitRatio = 0.5
                            subSplitRatio = 0.5
                        }
                case .twoLeftOneRight:
                    renderTwoLeftOneRight(width: max(10, totalWidth - 8), height: max(10, totalHeight - 8))
                        .padding(4)
                        .onChange(of: sessionManager.activeLayout.id) { _, _ in
                            splitRatio = 0.5
                            subSplitRatio = 0.5
                        }
                case .oneTopTwoBottom:
                    renderOneTopTwoBottom(width: max(10, totalWidth - 8), height: max(10, totalHeight - 8))
                        .padding(4)
                        .onChange(of: sessionManager.activeLayout.id) { _, _ in
                            splitRatio = 0.5
                            subSplitRatio = 0.5
                        }
                case .standardGrid:
                    renderStandardGrid(totalWidth: totalWidth, totalHeight: totalHeight)
                }
            }
        }
    }
    
    // MARK: - 3-Terminal Split: 1 Left Full-Height, 2 Right Stacked (Top & Bottom)
    @ViewBuilder
    private func renderOneLeftTwoRight(width: CGFloat, height: CGFloat) -> some View {
        let availW = max(10, width - dividerSize)
        let availH = max(10, height - dividerSize)
        
        let leftW = max(60, availW * splitRatio)
        let rightW = max(60, availW - leftW)
        
        let topRightH = max(40, availH * subSplitRatio)
        let bottomRightH = max(40, availH - topRightH)
        
        let sessions = sessionManager.visibleSessions
        
        HStack(spacing: 0) {
            // Left Pane (Full height)
            if sessions.indices.contains(0) {
                let session = sessions[0]
                TerminalPaneView(
                    session: session,
                    isFocused: sessionManager.activeSessionId == session.id,
                    shortcutIndex: 1,
                    onFocus: {
                        sessionManager.setActiveSession(session)
                        session.focus()
                    },
                    onMaximize: { sessionManager.toggleMaximize(for: session) },
                    onClose: { sessionManager.closeSession(session) },
                    onRestart: { sessionManager.restartSession(session) },
                    onClear: { session.clear() }
                )
                .frame(width: leftW, height: height)
            }
            
            // Vertical Resizable Divider
            ColumnDivider(
                height: height,
                dividerSize: dividerSize,
                onDrag: { delta in
                    let newLeftW = leftW + delta
                    let ratio = newLeftW / availW
                    splitRatio = min(0.85, max(0.15, ratio))
                },
                onDoubleTap: {
                    splitRatio = 0.5
                }
            )
            
            // Right Column (Stacked Top & Bottom)
            VStack(spacing: 0) {
                // Top Right Pane
                if sessions.indices.contains(1) {
                    let session = sessions[1]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 2,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: rightW, height: topRightH)
                }
                
                // Horizontal Resizable Divider
                RowDivider(
                    width: rightW,
                    dividerSize: dividerSize,
                    onDrag: { delta in
                        let newTopH = topRightH + delta
                        let ratio = newTopH / availH
                        subSplitRatio = min(0.85, max(0.15, ratio))
                    },
                    onDoubleTap: {
                        subSplitRatio = 0.5
                    }
                )
                
                // Bottom Right Pane
                if sessions.indices.contains(2) {
                    let session = sessions[2]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 3,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: rightW, height: bottomRightH)
                }
            }
            .frame(width: rightW, height: height)
        }
    }
    
    // MARK: - 3-Terminal Split: 2 Left Stacked (Top & Bottom), 1 Right Full-Height
    @ViewBuilder
    private func renderTwoLeftOneRight(width: CGFloat, height: CGFloat) -> some View {
        let availW = max(10, width - dividerSize)
        let availH = max(10, height - dividerSize)
        
        let leftW = max(60, availW * splitRatio)
        let rightW = max(60, availW - leftW)
        
        let topLeftH = max(40, availH * subSplitRatio)
        let bottomLeftH = max(40, availH - topLeftH)
        
        let sessions = sessionManager.visibleSessions
        
        HStack(spacing: 0) {
            // Left Column (Stacked Top & Bottom)
            VStack(spacing: 0) {
                if sessions.indices.contains(0) {
                    let session = sessions[0]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 1,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: leftW, height: topLeftH)
                }
                
                RowDivider(
                    width: leftW,
                    dividerSize: dividerSize,
                    onDrag: { delta in
                        let newTopH = topLeftH + delta
                        let ratio = newTopH / availH
                        subSplitRatio = min(0.85, max(0.15, ratio))
                    },
                    onDoubleTap: {
                        subSplitRatio = 0.5
                    }
                )
                
                if sessions.indices.contains(1) {
                    let session = sessions[1]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 2,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: leftW, height: bottomLeftH)
                }
            }
            .frame(width: leftW, height: height)
            
            ColumnDivider(
                height: height,
                dividerSize: dividerSize,
                onDrag: { delta in
                    let newLeftW = leftW + delta
                    let ratio = newLeftW / availW
                    splitRatio = min(0.85, max(0.15, ratio))
                },
                onDoubleTap: {
                    splitRatio = 0.5
                }
            )
            
            // Right Pane (Full height)
            if sessions.indices.contains(2) {
                let session = sessions[2]
                TerminalPaneView(
                    session: session,
                    isFocused: sessionManager.activeSessionId == session.id,
                    shortcutIndex: 3,
                    onFocus: {
                        sessionManager.setActiveSession(session)
                        session.focus()
                    },
                    onMaximize: { sessionManager.toggleMaximize(for: session) },
                    onClose: { sessionManager.closeSession(session) },
                    onRestart: { sessionManager.restartSession(session) },
                    onClear: { session.clear() }
                )
                .frame(width: rightW, height: height)
            }
        }
    }
    
    // MARK: - 3-Terminal Split: 1 Top Full-Width, 2 Bottom Side-by-Side
    @ViewBuilder
    private func renderOneTopTwoBottom(width: CGFloat, height: CGFloat) -> some View {
        let availW = max(10, width - dividerSize)
        let availH = max(10, height - dividerSize)
        
        let topH = max(40, availH * splitRatio)
        let bottomH = max(40, availH - topH)
        
        let bottomLeftW = max(60, availW * subSplitRatio)
        let bottomRightW = max(60, availW - bottomLeftW)
        
        let sessions = sessionManager.visibleSessions
        
        VStack(spacing: 0) {
            // Top Pane (Full width)
            if sessions.indices.contains(0) {
                let session = sessions[0]
                TerminalPaneView(
                    session: session,
                    isFocused: sessionManager.activeSessionId == session.id,
                    shortcutIndex: 1,
                    onFocus: {
                        sessionManager.setActiveSession(session)
                        session.focus()
                    },
                    onMaximize: { sessionManager.toggleMaximize(for: session) },
                    onClose: { sessionManager.closeSession(session) },
                    onRestart: { sessionManager.restartSession(session) },
                    onClear: { session.clear() }
                )
                .frame(width: width, height: topH)
            }
            
            RowDivider(
                width: width,
                dividerSize: dividerSize,
                onDrag: { delta in
                    let newTopH = topH + delta
                    let ratio = newTopH / availH
                    splitRatio = min(0.85, max(0.15, ratio))
                },
                onDoubleTap: {
                    splitRatio = 0.5
                }
            )
            
            // Bottom Row (Left & Right)
            HStack(spacing: 0) {
                if sessions.indices.contains(1) {
                    let session = sessions[1]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 2,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: bottomLeftW, height: bottomH)
                }
                
                ColumnDivider(
                    height: bottomH,
                    dividerSize: dividerSize,
                    onDrag: { delta in
                        let newLeftW = bottomLeftW + delta
                        let ratio = newLeftW / availW
                        subSplitRatio = min(0.85, max(0.15, ratio))
                    },
                    onDoubleTap: {
                        subSplitRatio = 0.5
                    }
                )
                
                if sessions.indices.contains(2) {
                    let session = sessions[2]
                    TerminalPaneView(
                        session: session,
                        isFocused: sessionManager.activeSessionId == session.id,
                        shortcutIndex: 3,
                        onFocus: {
                            sessionManager.setActiveSession(session)
                            session.focus()
                        },
                        onMaximize: { sessionManager.toggleMaximize(for: session) },
                        onClose: { sessionManager.closeSession(session) },
                        onRestart: { sessionManager.restartSession(session) },
                        onClear: { session.clear() }
                    )
                    .frame(width: bottomRightW, height: bottomH)
                }
            }
            .frame(width: width, height: bottomH)
        }
    }
    
    // MARK: - Standard MxN Grid View
    @ViewBuilder
    private func renderStandardGrid(totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        let currentCols = max(1, cols)
        let currentRows = max(1, rows)
        
        let availWidth = max(10, totalWidth - CGFloat(currentCols - 1) * dividerSize)
        let availHeight = max(10, totalHeight - CGFloat(currentRows - 1) * dividerSize)
        
        let effectiveColWeights = normalizedColWeights(count: currentCols)
        let effectiveRowWeights = normalizedRowWeights(count: currentRows)
        
        VStack(spacing: 0) {
            ForEach(0..<currentRows, id: \.self) { r in
                let rowHeight = availHeight * effectiveRowWeights[r]
                
                HStack(spacing: 0) {
                    ForEach(0..<currentCols, id: \.self) { c in
                        let colWidth = availWidth * effectiveColWeights[c]
                        let cellIndex = r * currentCols + c
                        
                        if cellIndex < sessionManager.visibleSessions.count {
                            let session = sessionManager.visibleSessions[cellIndex]
                            let isFocused = sessionManager.activeSessionId == session.id
                            
                            TerminalPaneView(
                                session: session,
                                isFocused: isFocused,
                                shortcutIndex: cellIndex + 1,
                                onFocus: {
                                    sessionManager.setActiveSession(session)
                                    session.focus()
                                },
                                onMaximize: {
                                    sessionManager.toggleMaximize(for: session)
                                },
                                onClose: {
                                    sessionManager.closeSession(session)
                                },
                                onRestart: {
                                    sessionManager.restartSession(session)
                                },
                                onClear: {
                                    session.clear()
                                }
                            )
                            .frame(width: max(40, colWidth), height: max(40, rowHeight))
                        } else {
                            Color.black.opacity(0.3)
                                .frame(width: max(40, colWidth), height: max(40, rowHeight))
                        }
                        
                        // Vertical divider between columns
                        if c < currentCols - 1 {
                            ColumnDivider(
                                height: rowHeight,
                                dividerSize: dividerSize,
                                onDrag: { delta in
                                    adjustColWeight(at: c, delta: delta, totalWidth: availWidth)
                                },
                                onDoubleTap: {
                                    resetColWeights(count: currentCols)
                                }
                            )
                        }
                    }
                }
                .frame(height: max(40, rowHeight))
                
                // Horizontal divider between rows
                if r < currentRows - 1 {
                    RowDivider(
                        width: totalWidth,
                        dividerSize: dividerSize,
                        onDrag: { delta in
                            adjustRowWeight(at: r, delta: delta, totalHeight: availHeight)
                        },
                        onDoubleTap: {
                            resetRowWeights(count: currentRows)
                        }
                    )
                }
            }
        }
        .padding(4)
        .onAppear {
            syncWeightsIfNeeded()
        }
        .onChange(of: sessionManager.activeLayout.id) { _, _ in
            syncWeightsIfNeeded()
        }
    }
    
    private func syncWeightsIfNeeded() {
        let currentLayoutId = sessionManager.activeLayout.id
        if lastLayoutId != currentLayoutId {
            lastLayoutId = currentLayoutId
            resetColWeights(count: max(1, cols))
            resetRowWeights(count: max(1, rows))
        }
    }
    
    private func normalizedColWeights(count: Int) -> [CGFloat] {
        if colWeights.count != count {
            return Array(repeating: 1.0 / CGFloat(count), count: count)
        }
        let sum = colWeights.reduce(0, +)
        guard sum > 0.001 else {
            return Array(repeating: 1.0 / CGFloat(count), count: count)
        }
        return colWeights.map { $0 / sum }
    }
    
    private func normalizedRowWeights(count: Int) -> [CGFloat] {
        if rowWeights.count != count {
            return Array(repeating: 1.0 / CGFloat(count), count: count)
        }
        let sum = rowWeights.reduce(0, +)
        guard sum > 0.001 else {
            return Array(repeating: 1.0 / CGFloat(count), count: count)
        }
        return rowWeights.map { $0 / sum }
    }
    
    private func resetColWeights(count: Int) {
        colWeights = Array(repeating: 1.0 / CGFloat(count), count: count)
    }
    
    private func resetRowWeights(count: Int) {
        rowWeights = Array(repeating: 1.0 / CGFloat(count), count: count)
    }
    
    private func adjustColWeight(at index: Int, delta: CGFloat, totalWidth: CGFloat) {
        guard totalWidth > 50 else { return }
        let currentWeights = normalizedColWeights(count: max(1, cols))
        guard index >= 0 && index + 1 < currentWeights.count else { return }
        
        let deltaFraction = delta / totalWidth
        let minWeight = 60.0 / totalWidth
        
        var w1 = currentWeights[index] + deltaFraction
        var w2 = currentWeights[index + 1] - deltaFraction
        
        if w1 < minWeight {
            let diff = minWeight - w1
            w1 = minWeight
            w2 -= diff
        } else if w2 < minWeight {
            let diff = minWeight - w2
            w2 = minWeight
            w1 -= diff
        }
        
        guard w1 >= minWeight && w2 >= minWeight else { return }
        
        var newWeights = currentWeights
        newWeights[index] = w1
        newWeights[index + 1] = w2
        self.colWeights = newWeights
    }
    
    private func adjustRowWeight(at index: Int, delta: CGFloat, totalHeight: CGFloat) {
        guard totalHeight > 50 else { return }
        let currentWeights = normalizedRowWeights(count: max(1, rows))
        guard index >= 0 && index + 1 < currentWeights.count else { return }
        
        let deltaFraction = delta / totalHeight
        let minWeight = 40.0 / totalHeight
        
        var h1 = currentWeights[index] + deltaFraction
        var h2 = currentWeights[index + 1] - deltaFraction
        
        if h1 < minWeight {
            let diff = minWeight - h1
            h1 = minWeight
            h2 -= diff
        } else if h2 < minWeight {
            let diff = minWeight - h2
            h2 = minWeight
            h1 -= diff
        }
        
        guard h1 >= minWeight && h2 >= minWeight else { return }
        
        var newWeights = currentWeights
        newWeights[index] = h1
        newWeights[index + 1] = h2
        self.rowWeights = newWeights
    }
}

private struct ColumnDivider: View {
    let height: CGFloat
    let dividerSize: CGFloat
    let onDrag: (CGFloat) -> Void
    let onDoubleTap: () -> Void
    
    @State private var isHovering = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isHovering ? Color.cyan.opacity(0.85) : Color.white.opacity(0.06))
                .frame(width: dividerSize, height: height)
                .shadow(color: isHovering ? Color.cyan.opacity(0.6) : Color.clear, radius: 4)
        }
        .contentShape(Rectangle().inset(by: -3))
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let delta = value.translation.width - dragOffset
                    dragOffset = value.translation.width
                    onDrag(delta)
                }
                .onEnded { _ in
                    dragOffset = 0
                }
        )
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}

private struct RowDivider: View {
    let width: CGFloat
    let dividerSize: CGFloat
    let onDrag: (CGFloat) -> Void
    let onDoubleTap: () -> Void
    
    @State private var isHovering = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isHovering ? Color.cyan.opacity(0.85) : Color.white.opacity(0.06))
                .frame(width: width, height: dividerSize)
                .shadow(color: isHovering ? Color.cyan.opacity(0.6) : Color.clear, radius: 4)
        }
        .contentShape(Rectangle().inset(by: -3))
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let delta = value.translation.height - dragOffset
                    dragOffset = value.translation.height
                    onDrag(delta)
                }
                .onEnded { _ in
                    dragOffset = 0
                }
        )
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}
