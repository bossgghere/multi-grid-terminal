import SwiftUI
import AppKit

public struct GridSelectorPopoverView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    @State private var hoverRow: Int = 0
    @State private var hoverCol: Int = 0
    @State private var customRows: Int = 2
    @State private var customCols: Int = 2
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Select Grid Layout")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if hoverRow > 0 && hoverCol > 0 {
                    Text("\(hoverRow) × \(hoverCol)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                } else {
                    Text(sessionManager.activeLayout.displayName)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Interactive 4x4 matrix picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Grid Picker")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    ForEach(1...4, id: \.self) { r in
                        HStack(spacing: 4) {
                            ForEach(1...4, id: \.self) { c in
                                let isHighlighted = (r <= hoverRow && c <= hoverCol) ||
                                    (hoverRow == 0 && r <= sessionManager.activeLayout.rows && c <= sessionManager.activeLayout.cols)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isHighlighted ? Color.blue : Color.white.opacity(0.12))
                                    .frame(width: 22, height: 18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(isHighlighted ? Color.blue.opacity(0.8) : Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                    .onHover { isHovered in
                                        if isHovered {
                                            hoverRow = r
                                            hoverCol = c
                                        }
                                    }
                                    .onTapGesture {
                                        sessionManager.setLayout(GridLayout(rows: r, cols: c))
                                        isPresented = false
                                    }
                            }
                        }
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
                .onHover { isHovered in
                    if !isHovered {
                        hoverRow = 0
                        hoverCol = 0
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Standard Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("Presets")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(GridLayout.presets) { preset in
                        Button(action: {
                            sessionManager.setLayout(preset)
                            isPresented = false
                        }) {
                            HStack {
                                MiniGridIcon(rows: preset.rows, cols: preset.cols)
                                    .frame(width: 16, height: 14)
                                Text(preset.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                if sessionManager.activeLayout == preset && !sessionManager.isMaximized {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                sessionManager.activeLayout == preset ? Color.blue.opacity(0.15) : Color.white.opacity(0.05)
                            )
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Custom Rows / Cols Steppers
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Dimensions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Stepper("Rows: \(customRows)", value: $customRows, in: 1...5)
                        .font(.system(size: 11))
                    Stepper("Cols: \(customCols)", value: $customCols, in: 1...5)
                        .font(.system(size: 11))
                }
                
                Button(action: {
                    sessionManager.setLayout(GridLayout(rows: customRows, cols: customCols))
                    isPresented = false
                }) {
                    Text("Apply Custom (\(customRows) × \(customCols))")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 250)
        .background(Color(nsColor: NSColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0)))
        .onAppear {
            customRows = sessionManager.activeLayout.rows
            customCols = sessionManager.activeLayout.cols
        }
    }
}

public struct MiniGridIcon: View {
    let rows: Int
    let cols: Int
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let r = max(1, rows)
            let c = max(1, cols)
            let cellW = (w - CGFloat(c - 1) * 1.5) / CGFloat(c)
            let cellH = (h - CGFloat(r - 1) * 1.5) / CGFloat(r)
            
            VStack(spacing: 1.5) {
                ForEach(0..<r, id: \.self) { _ in
                    HStack(spacing: 1.5) {
                        ForEach(0..<c, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primary.opacity(0.7))
                                .frame(width: max(2, cellW), height: max(2, cellH))
                        }
                    }
                }
            }
        }
    }
}

public struct WorkingDirectoryToolbarItem: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showingOptions = false
    
    private var folderName: String {
        let path = sessionManager.selectedWorkingDirectory.path
        let home = NSHomeDirectory()
        if path == home {
            return "~ (Home)"
        }
        return sessionManager.selectedWorkingDirectory.lastPathComponent
    }
    
    public var body: some View {
        Menu {
            Button("Choose Project Folder...") {
                chooseFolder()
            }
            
            Divider()
            
            Button("Open Directory in Active Terminal (cd)") {
                sessionManager.openWorkingDirectoryInActiveTerminal()
            }
            
            Button("Open Directory in All Terminals (cd)") {
                sessionManager.openWorkingDirectoryInAllTerminals()
            }
            
            Divider()
            
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: sessionManager.selectedWorkingDirectory.path)
            }
            
            Button("Copy Folder Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(sessionManager.selectedWorkingDirectory.path, forType: .string)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 11))
                Text(folderName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .cornerRadius(5)
        }
        .menuStyle(.borderlessButton)
        .help("Working Directory: \(sessionManager.selectedWorkingDirectory.path)")
    }
    
    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.directoryURL = sessionManager.selectedWorkingDirectory
        
        if panel.runModal() == .OK, let url = panel.url {
            sessionManager.selectWorkingDirectory(url)
        }
    }
}
