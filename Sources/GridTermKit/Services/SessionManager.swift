import Foundation
import AppKit
import SwiftUI

@MainActor
public final class SessionManager: ObservableObject {
    @Published public var activeLayout: GridLayout = .preset2x2 {
        didSet {
            ensureSessionsForCurrentLayout()
        }
    }
    
    @Published public var selectedWorkingDirectory: URL
    @Published public var sessions: [TerminalSession] = []
    @Published public var activeSessionId: UUID? = nil
    @Published public var globalFontSize: CGFloat = 13.0 {
        didSet {
            for session in sessions {
                session.fontSize = globalFontSize
            }
        }
    }
    
    @Published public var isMaximized: Bool = false
    @Published public var maximizedSessionId: UUID? = nil
    
    public init() {
        let defaultDir: URL
        if let currentPath = ProcessInfo.processInfo.environment["PWD"],
           FileManager.default.fileExists(atPath: currentPath) {
            defaultDir = URL(fileURLWithPath: currentPath)
        } else {
            defaultDir = FileManager.default.homeDirectoryForCurrentUser
        }
        self.selectedWorkingDirectory = defaultDir
        
        ensureSessionsForCurrentLayout()
        if let first = sessions.first {
            activeSessionId = first.id
        }
    }
    
    public var visibleSessions: [TerminalSession] {
        if isMaximized, let maxId = maximizedSessionId,
           let session = sessions.first(where: { $0.id == maxId }) {
            return [session]
        }
        let needed = activeLayout.count
        return Array(sessions.prefix(needed))
    }
    
    public var activeSession: TerminalSession? {
        guard let id = activeSessionId else { return sessions.first }
        return sessions.first(where: { $0.id == id }) ?? sessions.first
    }
    
    public var idleSessionCount: Int {
        max(0, sessions.count - visibleSessions.count)
    }
    
    public func renumberSessions() {
        for (index, session) in sessions.enumerated() {
            session.sessionNumber = index + 1
            if session.title.hasPrefix("Terminal ") {
                session.title = "Terminal \(index + 1)"
            }
        }
    }
    
    public func pruneInactiveSessions() {
        let needed = activeLayout.count
        if sessions.count > needed {
            let toRemove = Array(sessions.suffix(from: needed))
            for s in toRemove {
                s.terminalView.terminate()
            }
            sessions.removeSubrange(needed..<sessions.count)
            renumberSessions()
        }
    }
    
    public func ensureSessionsForCurrentLayout() {
        let needed = activeLayout.count
        while sessions.count < needed {
            let nextNumber = sessions.count + 1
            let newSession = TerminalSession(
                sessionNumber: nextNumber,
                workingDirectory: selectedWorkingDirectory,
                initialFontSize: globalFontSize
            )
            newSession.onFocusRequested = { [weak self] session in
                self?.setActiveSession(session)
            }
            sessions.append(newSession)
        }
        
        renumberSessions()
        
        // If current active session is no longer visible, move focus to the first visible session
        let visible = visibleSessions
        if let currentActive = activeSessionId, !visible.contains(where: { $0.id == currentActive }) {
            activeSessionId = visible.first?.id
        }
    }
    
    public func addTerminalPane() {
        switch activeLayout.count {
        case 1:
            setLayout(.preset1x2)
        case 2:
            setLayout(.preset1Left2Right)
        case 3:
            setLayout(.preset2x2)
        case 4:
            setLayout(.preset2x3)
        default:
            setLayout(GridLayout(rows: activeLayout.rows, cols: min(6, activeLayout.cols + 1)))
        }
    }
    
    public func removeTerminalPane() {
        switch activeLayout.count {
        case 2:
            setLayout(.preset1x1)
        case 3:
            setLayout(.preset1x2)
        case 4:
            setLayout(.preset1Left2Right)
        case 6:
            setLayout(.preset2x2)
        default:
            if activeLayout.cols > 1 {
                setLayout(GridLayout(rows: activeLayout.rows, cols: max(1, activeLayout.cols - 1)))
            } else if activeLayout.rows > 1 {
                setLayout(GridLayout(rows: max(1, activeLayout.rows - 1), cols: 1))
            }
        }
    }
    
    public func setLayout(_ layout: GridLayout) {
        if isMaximized {
            isMaximized = false
            maximizedSessionId = nil
        }
        activeLayout = layout
        ensureSessionsForCurrentLayout()
        
        // Small delay to allow views to settle before focusing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.focusActiveSession()
        }
    }
    
    public func setActiveSession(_ session: TerminalSession) {
        activeSessionId = session.id
    }
    
    public func focusActiveSession() {
        activeSession?.focus()
    }
    
    public func focusTerminal(at index: Int) {
        let visible = visibleSessions
        guard index >= 0 && index < visible.count else { return }
        let session = visible[index]
        activeSessionId = session.id
        session.focus()
    }
    
    public func selectWorkingDirectory(_ newDirectory: URL) {
        selectedWorkingDirectory = newDirectory
    }
    
    public func openWorkingDirectoryInActiveTerminal() {
        guard let active = activeSession else { return }
        let escapedPath = selectedWorkingDirectory.path.replacingOccurrences(of: " ", with: "\\ ")
        active.terminalView.send(txt: "cd \(escapedPath)\n")
    }
    
    public func openWorkingDirectoryInAllTerminals() {
        let escapedPath = selectedWorkingDirectory.path.replacingOccurrences(of: " ", with: "\\ ")
        for session in visibleSessions {
            session.terminalView.send(txt: "cd \(escapedPath)\n")
        }
    }
    
    public func toggleMaximize(for session: TerminalSession) {
        if isMaximized && maximizedSessionId == session.id {
            isMaximized = false
            maximizedSessionId = nil
        } else {
            isMaximized = true
            maximizedSessionId = session.id
            activeSessionId = session.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            session.focus()
        }
    }
    
    public func restartSession(_ session: TerminalSession) {
        session.restart(in: selectedWorkingDirectory)
        session.focus()
    }
    
    public func closeSession(_ session: TerminalSession) {
        session.terminalView.terminate()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: index)
        }
        ensureSessionsForCurrentLayout()
        renumberSessions()
        focusActiveSession()
    }
    
    public func clearActiveTerminal() {
        activeSession?.clear()
    }
    
    public func zoomIn() {
        if globalFontSize < 36 {
            globalFontSize += 1.0
        }
    }
    
    public func zoomOut() {
        if globalFontSize > 8 {
            globalFontSize -= 1.0
        }
    }
    
    public func resetZoom() {
        globalFontSize = 13.0
    }
}
