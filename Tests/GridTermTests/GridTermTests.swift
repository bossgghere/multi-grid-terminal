import XCTest
@testable import GridTermKit
import SwiftTerm

@MainActor
final class GridTermTests: XCTestCase {
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
    
    func testShellEnvironment() {
        let shell = ShellEnvironment.defaultShell
        XCTAssertFalse(shell.isEmpty)
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: shell))
        
        let env = ShellEnvironment.makeEnvironment()
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("TERM=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("COLORTERM=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("PATH=") }))
        XCTAssertTrue(env.contains(where: { $0.hasPrefix("SHELL=") }))
    }
    
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
        // Sessions 3 and 4 must remain alive in manager.sessions
        XCTAssertEqual(manager.sessions.count, 4)
        XCTAssertEqual(manager.sessions[2].id, session3Id)
        XCTAssertEqual(manager.sessions[3].id, session4Id)
        
        // Switch to 2x3 (6 sessions needed)
        manager.setLayout(.preset2x3)
        XCTAssertEqual(manager.activeLayout, .preset2x3)
        XCTAssertEqual(manager.visibleSessions.count, 6)
        XCTAssertEqual(manager.sessions.count, 6)
        // Sessions 1-4 must still be identical
        XCTAssertEqual(manager.sessions[0].id, session1Id)
        XCTAssertEqual(manager.sessions[1].id, session2Id)
        XCTAssertEqual(manager.sessions[2].id, session3Id)
        XCTAssertEqual(manager.sessions[3].id, session4Id)
    }
    
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
    
    func testZoomControls() {
        let manager = SessionManager()
        let initial = manager.globalFontSize
        
        manager.zoomIn()
        XCTAssertEqual(manager.globalFontSize, initial + 1.0)
        
        manager.zoomOut()
        XCTAssertEqual(manager.globalFontSize, initial)
        
        manager.resetZoom()
        XCTAssertEqual(manager.globalFontSize, 13.0)
    }
    
    func testMultipleTerminalsExecuteCommandsIndependently() {
        let tempFile1 = "/tmp/gridterm_test_cmd_1.txt"
        let tempFile2 = "/tmp/gridterm_test_cmd_2.txt"
        try? FileManager.default.removeItem(atPath: tempFile1)
        try? FileManager.default.removeItem(atPath: tempFile2)
        
        let session1 = TerminalSession(sessionNumber: 1)
        let session2 = TerminalSession(sessionNumber: 2)
        
        XCTAssertTrue(session1.isRunning)
        XCTAssertTrue(session2.isRunning)
        
        // Send independent commands to both terminals
        session1.terminalView.send(txt: "echo 'INDEPENDENT_1_PID='$$ > \(tempFile1)\n")
        session2.terminalView.send(txt: "echo 'INDEPENDENT_2_PID='$$ > \(tempFile2)\n")
        
        // Wait for shell execution
        let expectation = XCTestExpectation(description: "Wait for commands to write files")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile1), "Terminal 1 must create output file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile2), "Terminal 2 must create output file")
        
        let content1 = (try? String(contentsOfFile: tempFile1, encoding: .utf8)) ?? ""
        let content2 = (try? String(contentsOfFile: tempFile2, encoding: .utf8)) ?? ""
        
        XCTAssertTrue(content1.contains("INDEPENDENT_1_PID="), "Content 1: \(content1)")
        XCTAssertTrue(content2.contains("INDEPENDENT_2_PID="), "Content 2: \(content2)")
        
        // Verify distinct PIDs
        XCTAssertNotEqual(content1, content2, "PIDs of independent terminals must not be equal")
        
        try? FileManager.default.removeItem(atPath: tempFile1)
        try? FileManager.default.removeItem(atPath: tempFile2)
    }
}
