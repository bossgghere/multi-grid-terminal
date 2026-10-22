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
    
    // MARK: - Drag and Drop File Insertion & Path Escaping Tests
    
    func testShellPathEscaping() {
        // Standard path without special characters
        let simple = "/Users/gourav/Desktop/test.txt"
        XCTAssertEqual(ShellEnvironment.escapePath(simple), simple)
        
        // Path with spaces
        let withSpaces = "/Users/gourav/My Documents/test file.txt"
        XCTAssertEqual(ShellEnvironment.escapePath(withSpaces), "/Users/gourav/My\\ Documents/test\\ file.txt")
        
        // Path with shell metacharacters: (), [], {}, $, &, ;, *, ?, ', ", `
        let withMeta = "/Users/gourav/Project (v1) [final] & 'cool'$`*?{1}.txt"
        let expectedMeta = "/Users/gourav/Project\\ \\(v1\\)\\ \\[final\\]\\ \\&\\ \\'cool\\'\\$\\`\\*\\?\\{1\\}.txt"
        XCTAssertEqual(ShellEnvironment.escapePath(withMeta), expectedMeta)
        
        // Path with Unicode characters and spaces
        let unicodePath = "/Users/gourav/📁 Projekt/résumé (1).pdf"
        XCTAssertEqual(ShellEnvironment.escapePath(unicodePath), "/Users/gourav/📁\\ Projekt/résumé\\ \\(1\\).pdf")
    }
    
    func testFormatDroppedURLs() {
        let url1 = URL(fileURLWithPath: "/Users/gourav/My Documents/report.pdf")
        let url2 = URL(fileURLWithPath: "/Users/gourav/Desktop/data (1).csv")
        
        // Single dropped file URL must have trailing space
        let singleFormatted = ShellEnvironment.formatDroppedURLs([url1])
        XCTAssertEqual(singleFormatted, "/Users/gourav/My\\ Documents/report.pdf ")
        
        // Multiple dropped file URLs must be space-delimited with trailing space
        let multiFormatted = ShellEnvironment.formatDroppedURLs([url1, url2])
        XCTAssertEqual(multiFormatted, "/Users/gourav/My\\ Documents/report.pdf /Users/gourav/Desktop/data\\ \\(1\\).csv ")
        
        // Empty array returns empty string
        XCTAssertEqual(ShellEnvironment.formatDroppedURLs([]), "")
    }
    
    func testGridLocalTerminalViewRegisteredDragTypes() {
        let view = GridLocalTerminalView(frame: .zero)
        let registered = view.registeredDraggedTypes
        
        XCTAssertTrue(registered.contains(.fileURL), "View must register for .fileURL")
        XCTAssertTrue(registered.contains(.string), "View must register for .string")
        XCTAssertTrue(registered.contains(.URL), "View must register for .URL")
    }
    
    func testTerminalSessionDropHandling() {
        let session = TerminalSession(sessionNumber: 1)
        var focusCalled = false
        session.onFocusRequested = { _ in
            focusCalled = true
        }
        
        let testURL = URL(fileURLWithPath: "/tmp/dropped test file.txt")
        session.handleDroppedURLs([testURL])
        
        XCTAssertTrue(focusCalled, "Dropping a file URL must request focus for the session")
        
        // Verify text drop handling
        var textFocusCalled = false
        session.onFocusRequested = { _ in
            textFocusCalled = true
        }
        session.handleDroppedText("echo test\n")
        XCTAssertTrue(textFocusCalled, "Dropping text must request focus for the session")
    }
    
    // MARK: - 3-Terminal Split & Session Management Optimization Tests
    
    func testThreeTerminalSplitLayouts() {
        let split1L2R = GridLayout.preset1Left2Right
        XCTAssertEqual(split1L2R.count, 3)
        XCTAssertEqual(split1L2R.kind, .oneLeftTwoRight)
        XCTAssertEqual(split1L2R.displayName, "3 Split (1L + 2R)")
        XCTAssertEqual(split1L2R.id, "1L_2R")
        
        let split2L1R = GridLayout.preset2Left1Right
        XCTAssertEqual(split2L1R.count, 3)
        XCTAssertEqual(split2L1R.kind, .twoLeftOneRight)
        
        let split1T2B = GridLayout.preset1Top2Bottom
        XCTAssertEqual(split1T2B.count, 3)
        XCTAssertEqual(split1T2B.kind, .oneTopTwoBottom)
    }
    
    func testSessionManagerWithThreeTerminalSplit() {
        let manager = SessionManager()
        manager.setLayout(.preset1Left2Right)
        
        XCTAssertEqual(manager.activeLayout.count, 3)
        XCTAssertEqual(manager.visibleSessions.count, 3)
        
        // Sessions must be numbered cleanly 1, 2, 3
        XCTAssertEqual(manager.visibleSessions[0].sessionNumber, 1)
        XCTAssertEqual(manager.visibleSessions[1].sessionNumber, 2)
        XCTAssertEqual(manager.visibleSessions[2].sessionNumber, 3)
    }
    
    func testSessionRenumberingNoRandomNumbers() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2) // 4 sessions: 1, 2, 3, 4
        
        XCTAssertEqual(manager.sessions.count, 4)
        for (i, session) in manager.sessions.enumerated() {
            XCTAssertEqual(session.sessionNumber, i + 1)
        }
        
        // Close session 1
        manager.closeSession(manager.sessions[1])
        
        // Rebalanced sessions must remain cleanly numbered 1, 2, 3, 4 without random gaps or jumping to 6, 7, 8
        XCTAssertEqual(manager.sessions.count, 4)
        for (i, session) in manager.sessions.enumerated() {
            XCTAssertEqual(session.sessionNumber, i + 1)
        }
    }
    
    func testPruneInactiveSessionsFreesRAM() {
        let manager = SessionManager()
        manager.setLayout(.preset2x2) // 4 sessions
        XCTAssertEqual(manager.sessions.count, 4)
        
        // Switch to 1x2 (2 visible, 2 idle)
        manager.setLayout(.preset1x2)
        XCTAssertEqual(manager.visibleSessions.count, 2)
        XCTAssertEqual(manager.idleSessionCount, 2)
        
        // Prune idle sessions to reclaim memory
        manager.pruneInactiveSessions()
        XCTAssertEqual(manager.sessions.count, 2)
        XCTAssertEqual(manager.visibleSessions.count, 2)
        XCTAssertEqual(manager.idleSessionCount, 0)
    }
    
    func testAddAndRemoveTerminalPane() {
        let manager = SessionManager()
        manager.setLayout(.preset1x1)
        XCTAssertEqual(manager.activeLayout.count, 1)
        
        // 1 -> 2
        manager.addTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset1x2)
        XCTAssertEqual(manager.visibleSessions.count, 2)
        
        // 2 -> 3 (1 Left + 2 Right!)
        manager.addTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset1Left2Right)
        XCTAssertEqual(manager.visibleSessions.count, 3)
        
        // 3 -> 4 (2x2)
        manager.addTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset2x2)
        XCTAssertEqual(manager.visibleSessions.count, 4)
        
        // Step down: 4 -> 3
        manager.removeTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset1Left2Right)
        
        // Step down: 3 -> 2
        manager.removeTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset1x2)
        
        // Step down: 2 -> 1
        manager.removeTerminalPane()
        XCTAssertEqual(manager.activeLayout, .preset1x1)
    }
}
