import SwiftUI
import AppKit
import SwiftTerm

public final class GridLocalTerminalView: LocalProcessTerminalView {
    public var onMouseDown: (@MainActor () -> Void)?
    public var onDragTargetChanged: (@MainActor (Bool) -> Void)?
    public var onURLsDropped: (@MainActor ([URL]) -> Void)?
    public var onTextDropped: (@MainActor (String) -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDragAndDrop()
    }
    
    public override init(frame: CGRect, font: NSFont? = nil, options: TerminalOptions) {
        super.init(frame: frame, font: font, options: options)
        setupDragAndDrop()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }
    
    private func setupDragAndDrop() {
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }
    
    public override func mouseDown(with event: NSEvent) {
        onMouseDown?()
        super.mouseDown(with: event)
    }
    
    // MARK: - NSDraggingDestination
    
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) {
            onDragTargetChanged?(true)
            return .copy
        }
        return []
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) {
            return .copy
        }
        return []
    }
    
    public override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragTargetChanged?(false)
    }
    
    public override func draggingEnded(_ sender: NSDraggingInfo) {
        onDragTargetChanged?(false)
    }
    
    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard)
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDragTargetChanged?(false)
        guard ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) else { return false }
        
        let pboard = sender.draggingPasteboard
        let urls = ShellEnvironment.extractURLs(from: pboard)
        if !urls.isEmpty {
            if let onURLsDropped = onURLsDropped {
                onURLsDropped(urls)
            } else {
                handleDroppedURLs(urls)
            }
            return true
        }
        
        if let text = ShellEnvironment.extractString(from: pboard) {
            if let onTextDropped = onTextDropped {
                onTextDropped(text)
            } else {
                handleDroppedText(text)
            }
            return true
        }
        
        return false
    }
    
    public func handleDroppedURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let formatted = ShellEnvironment.formatDroppedURLs(urls)
        send(txt: formatted)
    }
    
    public func handleDroppedText(_ text: String) {
        guard !text.isEmpty else { return }
        send(txt: text)
    }
}

final class GridTerminalContainerNSView: NSView {
    weak var session: TerminalSession?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDragAndDrop()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }
    
    private func setupDragAndDrop() {
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) {
            session?.isDragTargeted = true
            return .copy
        }
        return []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) {
            return .copy
        }
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        session?.isDragTargeted = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        session?.isDragTargeted = false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        session?.isDragTargeted = false
        guard let session = session else { return false }
        guard ShellEnvironment.canHandleDrag(pasteboard: sender.draggingPasteboard) else { return false }
        
        let pboard = sender.draggingPasteboard
        let urls = ShellEnvironment.extractURLs(from: pboard)
        if !urls.isEmpty {
            session.handleDroppedURLs(urls)
            return true
        }
        if let text = ShellEnvironment.extractString(from: pboard) {
            session.handleDroppedText(text)
            return true
        }
        return false
    }
}

public struct TerminalContainerView: NSViewRepresentable {
    @ObservedObject var session: TerminalSession
    var isFocused: Bool
    
    public init(session: TerminalSession, isFocused: Bool) {
        self.session = session
        self.isFocused = isFocused
    }
    
    public func makeNSView(context: Context) -> NSView {
        let container = GridTerminalContainerNSView()
        container.session = session
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0).cgColor
        
        let tv = session.terminalView
        tv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tv)
        
        NSLayoutConstraint.activate([
            tv.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            tv.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            tv.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            tv.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])
        
        return container
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        if let container = nsView as? GridTerminalContainerNSView {
            container.session = session
        }
        
        if session.terminalView.superview != nsView {
            session.terminalView.removeFromSuperview()
            session.terminalView.translatesAutoresizingMaskIntoConstraints = false
            nsView.addSubview(session.terminalView)
            
            NSLayoutConstraint.activate([
                session.terminalView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor, constant: 4),
                session.terminalView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor, constant: -4),
                session.terminalView.topAnchor.constraint(equalTo: nsView.topAnchor, constant: 4),
                session.terminalView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor, constant: -4),
            ])
        }
        
        if isFocused {
            DispatchQueue.main.async {
                if let window = session.terminalView.window,
                   window.firstResponder != session.terminalView {
                    window.makeFirstResponder(session.terminalView)
                }
            }
        }
    }
}
