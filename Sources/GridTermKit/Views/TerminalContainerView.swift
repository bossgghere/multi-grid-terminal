import SwiftUI
import AppKit
import SwiftTerm

public final class GridLocalTerminalView: LocalProcessTerminalView {
    public var onMouseDown: (@MainActor () -> Void)?
    
    public override func mouseDown(with event: NSEvent) {
        onMouseDown?()
        super.mouseDown(with: event)
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
        let container = NSView()
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
