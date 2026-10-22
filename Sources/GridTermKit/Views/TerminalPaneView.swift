import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct TerminalPaneView: View {
    @ObservedObject var session: TerminalSession
    let isFocused: Bool
    let shortcutIndex: Int? // 1..9
    let onFocus: () -> Void
    let onMaximize: () -> Void
    let onClose: () -> Void
    let onRestart: () -> Void
    let onClear: () -> Void
    
    @State private var isHovering = false
    
    public init(
        session: TerminalSession,
        isFocused: Bool,
        shortcutIndex: Int?,
        onFocus: @escaping () -> Void,
        onMaximize: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onRestart: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        self.session = session
        self.isFocused = isFocused
        self.shortcutIndex = shortcutIndex
        self.onFocus = onFocus
        self.onMaximize = onMaximize
        self.onClose = onClose
        self.onRestart = onRestart
        self.onClear = onClear
    }
    
    private var cwdDisplayName: String {
        let path = session.currentDirectoryPath
        let home = NSHomeDirectory()
        if path == home {
            return "~"
        } else if path.hasPrefix(home) {
            let relative = path.dropFirst(home.count)
            return "~\(relative)"
        }
        return (path as NSString).lastPathComponent
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sleek Pane Header Bar
            HStack(spacing: 8) {
                // Session index pill & shortcut
                HStack(spacing: 5) {
                    // Running pulse indicator
                    Circle()
                        .fill(session.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : Color.orange)
                        .frame(width: 5, height: 5)
                        .shadow(color: session.isRunning ? Color.green.opacity(0.6) : Color.clear, radius: 3)
                    
                    Text("#\(shortcutIndex ?? session.sessionNumber)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isFocused ? .white : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isFocused ? Color(red: 0.08, green: 0.65, blue: 0.95) : Color.white.opacity(0.08))
                        )
                    
                    if let index = shortcutIndex, index <= 9 {
                        Text("⌘\(index)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(isFocused ? Color(red: 0.2, green: 0.8, blue: 1.0) : Color.secondary.opacity(0.7))
                    }
                }
                
                // Process title / Shell name
                Text(session.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isFocused ? .primary : .secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Dynamic Current Working Directory
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text(cwdDisplayName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(isFocused ? .secondary : .secondary.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.04))
                .cornerRadius(4)
                
                // Action buttons with sleek hover states
                HStack(spacing: 5) {
                    Button(action: onClear) {
                        Image(systemName: "sun.min")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Clear Terminal (⌘K)")
                    
                    Button(action: onRestart) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Restart Shell")
                    
                    Button(action: onMaximize) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Maximize / Restore Pane")
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isHovering ? .red.opacity(0.9) : .secondary)
                    .help("Close Terminal Pane")
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 27)
            .background(
                isFocused ? Color(nsColor: NSColor(red: 0.12, green: 0.14, blue: 0.19, alpha: 1.0)) :
                            Color(nsColor: NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onFocus()
            }
            .onDrop(of: [.fileURL, .text], isTargeted: Binding(
                get: { session.isDragTargeted },
                set: { session.isDragTargeted = $0 }
            )) { providers in
                var handled = false
                for provider in providers {
                    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async {
                                    session.handleDroppedURLs([url])
                                }
                            }
                        }
                        handled = true
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                        _ = provider.loadObject(ofClass: String.self) { text, _ in
                            if let text = text {
                                DispatchQueue.main.async {
                                    session.handleDroppedText(text)
                                }
                            }
                        }
                        handled = true
                    }
                }
                return handled
            }
            
            Divider()
                .background(isFocused ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
            
            // Terminal View
            TerminalContainerView(session: session, isFocused: isFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: NSColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1.0)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    (isFocused || session.isDragTargeted) ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.85, blue: 1.0),
                                Color(red: 0.45, green: 0.40, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: (isFocused || session.isDragTargeted) ? 1.5 : 1.0
                )
        )
        .shadow(
            color: (isFocused || session.isDragTargeted) ? Color(red: 0.1, green: 0.75, blue: 1.0).opacity(session.isDragTargeted ? 0.45 : 0.28) : Color.clear,
            radius: session.isDragTargeted ? 12 : 8,
            x: 0,
            y: 0
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
