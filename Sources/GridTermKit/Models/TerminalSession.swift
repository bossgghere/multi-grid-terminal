import Foundation
import AppKit
import SwiftTerm

@MainActor
public final class TerminalSession: NSObject, Identifiable, ObservableObject {
    public let id: UUID
    public let sessionNumber: Int
    
    @Published public var title: String
    @Published public var currentDirectoryPath: String
    @Published public var isRunning: Bool = false
    @Published public var exitCode: Int32? = nil
    @Published public var fontSize: CGFloat = 13.0 {
        didSet {
            applyFont()
        }
    }
    
    public let terminalView: GridLocalTerminalView
    public var onFocusRequested: (@MainActor (TerminalSession) -> Void)?
    
    public init(sessionNumber: Int, workingDirectory: URL? = nil, initialFontSize: CGFloat = 13.0) {
        self.id = UUID()
        self.sessionNumber = sessionNumber
        self.title = "Terminal \(sessionNumber)"
        self.fontSize = initialFontSize
        let initialPath = workingDirectory?.path ?? NSHomeDirectory()
        self.currentDirectoryPath = initialPath
        
        let view = GridLocalTerminalView(frame: .zero)
        self.terminalView = view
        
        super.init()
        
        view.onMouseDown = { [weak self] in
            guard let self = self else { return }
            self.onFocusRequested?(self)
        }
        
        configureTerminalAppearance()
        view.processDelegate = self
        
        start(in: workingDirectory)
    }
    
    public func configureTerminalAppearance() {
        terminalView.nativeBackgroundColor = NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0)
        terminalView.nativeForegroundColor = NSColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1.0)
        terminalView.caretColor = NSColor.systemCyan
        terminalView.caretViewTracksFocus = true
        applyFont()
    }
    
    public func applyFont() {
        if let font = NSFont(name: "SF Mono", size: fontSize) ??
                      NSFont(name: "Menlo", size: fontSize) ??
                      NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular) as NSFont? {
            terminalView.font = font
        }
    }
    
    public func start(in directory: URL? = nil) {
        let launchDir = directory ?? URL(fileURLWithPath: currentDirectoryPath)
        let shell = ShellEnvironment.defaultShell
        let env = ShellEnvironment.makeEnvironment(workingDirectory: launchDir)
        
        currentDirectoryPath = launchDir.path
        isRunning = true
        exitCode = nil
        
        terminalView.startProcess(
            executable: shell,
            args: ["-l"],
            environment: env,
            execName: nil,
            currentDirectory: launchDir.path
        )
    }
    
    public func restart(in directory: URL? = nil) {
        if isRunning {
            terminalView.terminate()
        }
        start(in: directory)
    }
    
    public func clear() {
        // Send Ctrl+L or clear sequence
        terminalView.send(txt: "\u{000C}")
    }
    
    public func focus() {
        if let window = terminalView.window {
            window.makeFirstResponder(terminalView)
        }
        onFocusRequested?(self)
    }
}

extension TerminalSession: LocalProcessTerminalViewDelegate {
    public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // Window size updated by UI
    }
    
    public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            self.title = trimmed
        } else {
            self.title = "Terminal \(sessionNumber)"
        }
    }
    
    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        if let dir = directory, !dir.isEmpty {
            var path = dir
            if path.hasPrefix("file://") {
                if let url = URL(string: path) {
                    path = url.path
                }
            }
            self.currentDirectoryPath = path
        }
    }
    
    public func processTerminated(source: TerminalView, exitCode: Int32?) {
        self.isRunning = false
        self.exitCode = exitCode
    }
}
