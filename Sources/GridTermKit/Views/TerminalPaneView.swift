import SwiftUI
import AppKit

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
            // Header bar
            HStack(spacing: 8) {
                // Session index badge
                HStack(spacing: 4) {
                    Text("#\(session.sessionNumber)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isFocused ? .white : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isFocused ? Color.blue : Color.white.opacity(0.1))
                        )
                    
                    if let index = shortcutIndex, index <= 9 {
                        Text("⌘\(index)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(isFocused ? Color.blue : Color.secondary.opacity(0.8))
                    }
                }
                
                // Process title / Shell name
                Text(session.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isFocused ? .primary : .secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Current Directory
                HStack(spacing: 3) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                    Text(cwdDisplayName)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                
                // Action buttons
                HStack(spacing: 4) {
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
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isHovering ? .red : .secondary)
                    .help("Close Terminal Pane")
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(
                isFocused ? Color(nsColor: NSColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1.0)) :
                            Color(nsColor: NSColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onFocus()
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Terminal View
            TerminalContainerView(session: session, isFocused: isFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0)))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isFocused ? Color.blue.opacity(0.85) : Color.white.opacity(0.08),
                    lineWidth: isFocused ? 1.5 : 1.0
                )
        )
        .shadow(
            color: isFocused ? Color.blue.opacity(0.2) : Color.clear,
            radius: 4,
            x: 0,
            y: 0
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
