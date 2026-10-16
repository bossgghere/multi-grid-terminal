import SwiftUI
import AppKit

public struct MainWindowView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showingGridPopover = false
    
    public init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Resizable Terminal Grid
            ResizableGridView(sessionManager: sessionManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Minimalist Bottom Status Bar
            HStack(spacing: 12) {
                // Active pane indicator
                if let active = sessionManager.activeSession {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(active.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : Color.orange)
                            .frame(width: 5, height: 5)
                            .shadow(color: active.isRunning ? Color.green.opacity(0.5) : Color.clear, radius: 2)
                        
                        Text("Terminal #\(active.sessionNumber)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        if let index = sessionManager.visibleSessions.firstIndex(where: { $0.id == active.id }), index < 9 {
                            Text("(⌘\(index + 1))")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.cyan)
                        }
                    }
                }
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.3))
                
                // Current active terminal path
                if let active = sessionManager.activeSession {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(active.currentDirectoryPath.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
                
                Spacer()
                
                // Active Layout indicator
                HStack(spacing: 4) {
                    MiniGridIcon(rows: sessionManager.activeLayout.rows, cols: sessionManager.activeLayout.cols)
                        .frame(width: 10, height: 9)
                    Text("\(sessionManager.activeLayout.displayName) (\(sessionManager.visibleSessions.count) panes)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.3))
                
                // Keyboard hint
                Text("⌘1–⌘9: Focus • ⌘+/-: Font • ⌘K: Clear")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Color(nsColor: NSColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1.0)))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.05)),
                alignment: .top
            )
        }
        .background(Color(nsColor: NSColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1.0)))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Quick Layout Selector Pills in the toolbar
                QuickLayoutPillBar(
                    sessionManager: sessionManager,
                    showingPopover: $showingGridPopover
                )
                
                Spacer()
                
                // Font zoom controls
                FontZoomPillBar(sessionManager: sessionManager)
                
                // Clear active terminal button
                Button(action: {
                    sessionManager.clearActiveTerminal()
                }) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .cornerRadius(5)
                .help("Clear Terminal Screen (⌘K)")
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.control) {
                    if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                        // Focus ⌘1..⌘9
                        if let digit = Int(chars), digit >= 1 && digit <= 9 {
                            sessionManager.focusTerminal(at: digit - 1)
                            return nil
                        }
                        // Zoom in
                        if chars == "+" || chars == "=" || event.keyCode == 24 {
                            sessionManager.zoomIn()
                            return nil
                        }
                        // Zoom out
                        if chars == "-" || chars == "_" || event.keyCode == 27 {
                            sessionManager.zoomOut()
                            return nil
                        }
                        // Reset zoom
                        if chars == "0" {
                            sessionManager.resetZoom()
                            return nil
                        }
                        // Clear active terminal
                        if chars.lowercased() == "k" {
                            sessionManager.clearActiveTerminal()
                            return nil
                        }
                    }
                }
                return event
            }
        }
    }
}
