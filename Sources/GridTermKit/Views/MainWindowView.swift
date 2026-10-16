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
            // Main Terminal Grid
            ResizableGridView(sessionManager: sessionManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Minimal bottom status bar
            HStack(spacing: 12) {
                // Active pane indicator
                if let active = sessionManager.activeSession {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(active.isRunning ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text("Terminal #\(active.sessionNumber)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        if let index = sessionManager.visibleSessions.firstIndex(where: { $0.id == active.id }), index < 9 {
                            Text("(⌘\(index + 1))")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Layout indicator
                HStack(spacing: 4) {
                    MiniGridIcon(rows: sessionManager.activeLayout.rows, cols: sessionManager.activeLayout.cols)
                        .frame(width: 10, height: 9)
                    Text(sessionManager.activeLayout.displayName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Working Directory
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text(sessionManager.selectedWorkingDirectory.lastPathComponent)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Font size indicator
                Text("\(Int(sessionManager.globalFontSize))pt")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Keyboard hint
                Text("⌘1–⌘9: Focus • ⌘+/-: Font • ⌘K: Clear")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Color(nsColor: NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.06)),
                alignment: .top
            )
        }
        .background(Color(nsColor: NSColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1.0)))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Grid layout selector button
                Button(action: {
                    showingGridPopover.toggle()
                }) {
                    HStack(spacing: 5) {
                        MiniGridIcon(rows: sessionManager.activeLayout.rows, cols: sessionManager.activeLayout.cols)
                            .frame(width: 14, height: 12)
                        Text(sessionManager.activeLayout.displayName)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingGridPopover, arrowEdge: .bottom) {
                    GridSelectorPopoverView(
                        sessionManager: sessionManager,
                        isPresented: $showingGridPopover
                    )
                }
                .help("Select Grid Layout")
                
                // Working Directory Picker
                WorkingDirectoryToolbarItem(sessionManager: sessionManager)
                
                Spacer()
                
                // Quick Layout presets in toolbar
                HStack(spacing: 2) {
                    Button(action: { sessionManager.setLayout(.preset1x1) }) {
                        Text("1×1")
                            .font(.system(size: 10, weight: sessionManager.activeLayout == .preset1x1 ? .bold : .regular))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(sessionManager.activeLayout == .preset1x1 ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { sessionManager.setLayout(.preset1x2) }) {
                        Text("1×2")
                            .font(.system(size: 10, weight: sessionManager.activeLayout == .preset1x2 ? .bold : .regular))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(sessionManager.activeLayout == .preset1x2 ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { sessionManager.setLayout(.preset2x2) }) {
                        Text("2×2")
                            .font(.system(size: 10, weight: sessionManager.activeLayout == .preset2x2 ? .bold : .regular))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(sessionManager.activeLayout == .preset2x2 ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { sessionManager.setLayout(.preset3x3) }) {
                        Text("3×3")
                            .font(.system(size: 10, weight: sessionManager.activeLayout == .preset3x3 ? .bold : .regular))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(sessionManager.activeLayout == .preset3x3 ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
                .padding(2)
                .background(Color.white.opacity(0.06))
                .cornerRadius(5)
                
                // Font zoom controls
                HStack(spacing: 2) {
                    Button(action: { sessionManager.zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .help("Zoom Out (⌘-)")
                    
                    Button(action: { sessionManager.zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .help("Zoom In (⌘+)")
                }
                .padding(2)
                .background(Color.white.opacity(0.06))
                .cornerRadius(5)
                
                // Clear active terminal
                Button(action: {
                    sessionManager.clearActiveTerminal()
                }) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
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
                        if chars == "+" || chars == "=" {
                            sessionManager.zoomIn()
                            return nil
                        }
                        // Zoom out
                        if chars == "-" {
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
