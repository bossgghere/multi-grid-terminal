import SwiftUI
import AppKit
import GridTermKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct GridTermApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView(sessionManager: sessionManager)
                .preferredColorScheme(.dark)
                .frame(minWidth: 640, minHeight: 480)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Layout Menu Commands
            CommandMenu("Layout") {
                Button("1 × 1 Layout") {
                    sessionManager.setLayout(.preset1x1)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button("1 × 2 Layout") {
                    sessionManager.setLayout(.preset1x2)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
                
                Button("2 × 1 Layout") {
                    sessionManager.setLayout(.preset2x1)
                }
                .keyboardShortcut("3", modifiers: [.command, .option])
                
                Button("2 × 2 Layout") {
                    sessionManager.setLayout(.preset2x2)
                }
                .keyboardShortcut("4", modifiers: [.command, .option])
                
                Button("2 × 3 Layout") {
                    sessionManager.setLayout(.preset2x3)
                }
                .keyboardShortcut("5", modifiers: [.command, .option])
                
                Button("2 × 4 Layout") {
                    sessionManager.setLayout(.preset2x4)
                }
                .keyboardShortcut("6", modifiers: [.command, .option])
                
                Button("3 × 3 Layout") {
                    sessionManager.setLayout(.preset3x3)
                }
                .keyboardShortcut("7", modifiers: [.command, .option])
                
                Divider()
                
                Button("Toggle Maximize Active Pane") {
                    if let active = sessionManager.activeSession {
                        sessionManager.toggleMaximize(for: active)
                    }
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
            
            // Terminal Focus Commands: ⌘1 through ⌘9
            CommandMenu("Terminal") {
                ForEach(1...9, id: \.self) { num in
                    Button("Focus Terminal \(num)") {
                        sessionManager.focusTerminal(at: num - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(num)")), modifiers: .command)
                }
                
                Divider()
                
                Button("Clear Screen") {
                    sessionManager.clearActiveTerminal()
                }
                .keyboardShortcut("k", modifiers: .command)
                
                Button("Restart Active Shell") {
                    if let active = sessionManager.activeSession {
                        sessionManager.restartSession(active)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Button("Close Active Pane") {
                    if let active = sessionManager.activeSession {
                        sessionManager.closeSession(active)
                    }
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
            
            // View / Zoom Commands
            CommandGroup(replacing: .toolbar) {
                Button("Zoom In") {
                    sessionManager.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    sessionManager.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Actual Size") {
                    sessionManager.resetZoom()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            
            // Standard Edit Commands for Copy / Paste
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)
                
                Button("Copy") {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Paste") {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
            }
        }
    }
}
