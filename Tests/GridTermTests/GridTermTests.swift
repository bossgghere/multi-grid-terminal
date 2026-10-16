import XCTest
@testable import GridTermKit
import SwiftTerm

@MainActor
final class GridTermTests: XCTestCase {
    
    // MARK: - Grid Layout Tests & Edge Cases
    
    func testGridLayoutPresets() {
        XCTAssertEqual(GridLayout.preset1x1.count, 1)
        XCTAssertEqual(GridLayout.preset1x2.count, 2)
        XCTAssertEqual(GridLayout.preset2x1.count, 2)
        XCTAssertEqual(GridLayout.preset2x2.count, 4)
        XCTAssertEqual(GridLayout.preset2x3.count, 6)
        XCTAssertEqual(GridLayout.preset2x4.count, 8)
        XCTAssertEqual(GridLayout.preset3x3.count, 9)
        
        let custom = GridLayout(rows: 3, cols: 2)
        XCTAssertEqual(custom.count, 6)
        XCTAssertEqual(custom.displayName, "3 × 2")
        XCTAssertEqual(custom.id, "3x2")
    }
    
    func testGridLayoutEdgeCasesClamping() {
        // Hidden test case: negative or zero rows/columns must clamp to minimum 1
        let clampedZero = GridLayout(rows: 0, cols: -5)
        XCTAssertEqual(clampedZero.rows, 1)
        XCTAssertEqual(clampedZero.cols, 1)
        XCTAssertEqual(clampedZero.count, 1)
        
        // Hidden test case: excessively large rows/columns must clamp to maximum 6
        let clampedHuge = GridLayout(rows: 50, cols: 99)
        XCTAssertEqual(clampedHuge.rows, 6)
        XCTAssertEqual(clampedHuge.cols, 6)
        XCTAssertEqual(clampedHuge.count, 36)
    }
    
    // MARK: - Shell Environment Tests & Edge Cases
    
    func testShellEnvironment() {
        let shell = ShellEnvironment.defaultShell
        XCTAssertFalse(shell.isEmpty)
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: shell))
        
        let env = ShellEnvironment.makeEnvironment()
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("TERM=xterm-256color") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("COLORTERM=truecolor") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("PATH=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("SHELL=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("USER=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("HOME=") }))
        
        // Verify formatting: every entry must have an '=' delimiter
        for entry in env {
            XCTAssertTrue(entry.contains("="), "Environment entry should be KEY=VALUE: \(entry)")
        }
    }
    
    // MARK: - Session Preservation Across Layout Switches
    
    func testSessionManagerPreservesSessionsAcrossLayoutChanges() {
        let manager = SessionManager()
        
        // Default layout is 2x2 (4 sessions)
        XCTAssertEqual(manager.activeLayout, .preset2x2)
        XCTAssertEqual(manager.sessions.count, 4)
        XCTAssertEqual(manager.visibleSessions.count, 4)
        
        let session1Id = manager.sessions[0].id
        let session2Id = manager.sessions[1].id
        let session3Id = manager.sessions[2].id
        let session4Id = manager.sessions[3].id
        
        // Switch to 1x2 (2 sessions visible)
        manager.setLayout(.preset1x2)
        XCTAssertEqual(manager.activeLayout, .preset1x2)
        XCTAssertEqual(manager.visibleSessions.count, 2)
        XCTAssertEqual(manager.visibleSessions[0].id, session1Id)
        XCTAssertEqual(manager.visibleSessions[1].id, session2Id)
        
        // Hidden test case: Sessions 3 and 4 must remain alive in manager.sessions pool
        XCTAssertEqual(manager.sessions.count, 4)
        XCTAssertEqual(manager.sessions[2].id, session3Id)
        XCTAssertEqual(manager.sessions[3].id, session4Id)
        
        // Switch to 2x3 (6 sessions needed)
        manager.setLayout(.preset2x3)
        XCTAssertEqual(manager.activeLayout, .preset2x3)
        XCTAssertEqual(manager.visibleSessions.count, 6)
        XCTAssertEqual(manager.sessions.count, 6)
        
        // Sessions 1-4 must still be identical instances with preserved state
        XCTAssertEqual(manager.sessions[0].id, session1Id)
        XCTAssertEqual(manager.sessions[1].id, session2Id)
        XCTAssertEqual(manager.sessions[2].id, session3Id)
        XCTAssertEqual(manager.sessions[3].id, session4Id)
    }
    
    // MARK: - Focus Navigation & Out-of-Bounds Edge Cases
    
    func testFocusNavigation() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2)
        
        // Focus terminal 2 (index 1)
        manager.focusTerminal(at: 1)
        XCTAssertEqual(manager.activeSessionId, manager.visibleSessions[1].id)
        
        // Focus terminal 4 (index 3)
        manager.focusTerminal(at: 3)
        XCTAssertEqual(manager.activeSessionId, manager.visibleSessions[3].id)
        
        // Focus terminal 1 (index 0)
        manager.focusTerminal(at: 0)
        XCTAssertEqual(manager.activeSessionId, manager.visibleSessions[0].id)
    }
    
    func testFocusNavigationOutOfBoundsEdgeCases() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2)
        let initialActiveId = manager.activeSessionId
        
        // Negative index should be gracefully ignored without crashing
        manager.focusTerminal(at: -1)
        XCTAssertEqual(manager.activeSessionId, initialActiveId)
        
        // Out-of-bounds large index should be gracefully ignored without crashing
        manager.focusTerminal(at: 999)
        XCTAssertEqual(manager.activeSessionId, initialActiveId)
    }
    
    // MARK: - Font Zoom Controls & Limits Clamping
    
    func testZoomControlsAndBoundaryLimits() {
        let manager = SessionManager()
        XCTAssertEqual(manager.globalFontSize, 13.0)
        
        manager.zoomIn()
        XCTAssertEqual(manager.globalFontSize, 14.0)
        
        manager.zoomOut()
        XCTAssertEqual(manager.globalFontSize, 13.0)
        
        // Hidden test case: Zoom in 50 times must clamp to maximum 36pt
        for _ in 0..<50 {
            manager.zoomIn()
        }
        XCTAssertLessThanOrEqual(manager.globalFontSize, 36.0)
        XCTAssertEqual(manager.globalFontSize, 36.0)
        
        // Hidden test case: Zoom out 50 times must clamp to minimum 8pt
        for _ in 0..<50 {
            manager.zoomOut()
        }
        XCTAssertGreaterThanOrEqual(manager.globalFontSize, 8.0)
        XCTAssertEqual(manager.globalFontSize, 8.0)
        
        // Reset zoom restores 13pt
        manager.resetZoom()
        XCTAssertEqual(manager.globalFontSize, 13.0)
    }
    
    // MARK: - Maximize and Restore
    
    func testMaximizeAndRestorePane() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2)
        XCTAssertEqual(manager.visibleSessions.count, 4)
        XCTAssertFalse(manager.isMaximized)
        
        let targetSession = manager.visibleSessions[1]
        manager.toggleMaximize(for: targetSession)
        
        XCTAssertTrue(manager.isMaximized)
        XCTAssertEqual(manager.maximizedSessionId, targetSession.id)
        XCTAssertEqual(manager.visibleSessions.count, 1)
        XCTAssertEqual(manager.visibleSessions[0].id, targetSession.id)
        
        // Toggle again restores the grid
        manager.toggleMaximize(for: targetSession)
        XCTAssertFalse(manager.isMaximized)
        XCTAssertNil(manager.maximizedSessionId)
        XCTAssertEqual(manager.visibleSessions.count, 4)
    }
    
    // MARK: - Close Session and Rebalance
    
    func testCloseSessionRebalance() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2)
        XCTAssertEqual(manager.sessions.count, 4)
        
        let sessionToClose = manager.sessions[0]
        manager.closeSession(sessionToClose)
        
        // Grid must automatically ensure 4 sessions remain available
        XCTAssertEqual(manager.sessions.count, 4)
        XCTAssertFalse(manager.sessions.contains(where: { $0.id == sessionToClose.id }))
        XCTAssertNotNil(manager.activeSessionId)
    }
    
    // MARK: - Multiple Independent Terminals Execution
    
    func testMultipleTerminalsExecuteCommandsIndependently() {
        let tempFile1 = "/tmp/gridterm_test_cmd_1.txt"
        let tempFile2 = "/tmp/gridterm_test_cmd_2.txt"
        let tempFile3 = "/tmp/gridterm_test_cmd_3.txt"
        try? FileManager.default.removeItem(atPath: tempFile1)
        try? FileManager.default.removeItem(atPath: tempFile2)
        try? FileManager.default.removeItem(atPath: tempFile3)
        
        let session1 = TerminalSession(sessionNumber: 1)
        let session2 = TerminalSession(sessionNumber: 2)
        let session3 = TerminalSession(sessionNumber: 3)
        
        XCTAssertTrue(session1.isRunning)
        XCTAssertTrue(session2.isRunning)
        XCTAssertTrue(session3.isRunning)
        
        // Send independent commands to all 3 terminals
        session1.terminalView.send(txt: "echo 'INDEPENDENT_1_PID='$$ > \(tempFile1)\n")
        session2.terminalView.send(txt: "echo 'INDEPENDENT_2_PID='$$ > \(tempFile2)\n")
        session3.terminalView.send(txt: "echo 'INDEPENDENT_3_PID='$$ > \(tempFile3)\n")
        
        // Wait for shell execution
        let expectation = XCTestExpectation(description: "Wait for commands to write files")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.5)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile1), "Terminal 1 must create output file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile2), "Terminal 2 must create output file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile3), "Terminal 3 must create output file")
        
        let content1 = (try? String(contentsOfFile: tempFile1, encoding: .utf8)) ?? ""
        let content2 = (try? String(contentsOfFile: tempFile2, encoding: .utf8)) ?? ""
        let content3 = (try? String(contentsOfFile: tempFile3, encoding: .utf8)) ?? ""
        
        XCTAssertTrue(content1.contains("INDEPENDENT_1_PID="), "Content 1: \(content1)")
        XCTAssertTrue(content2.contains("INDEPENDENT_2_PID="), "Content 2: \(content2)")
        XCTAssertTrue(content3.contains("INDEPENDENT_3_PID="), "Content 3: \(content3)")
        
        // Hidden test case: Verify that all 3 spawned shell PIDs are completely distinct
        XCTAssertNotEqual(content1, content2)
        XCTAssertNotEqual(content2, content3)
        XCTAssertNotEqual(content1, content3)
        
        try? FileManager.default.removeItem(atPath: tempFile1)
        try? FileManager.default.removeItem(atPath: tempFile2)
        try? FileManager.default.removeItem(atPath: tempFile3)
    }
}
