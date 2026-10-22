import Foundation
import AppKit

public enum ShellEnvironment {
    public static var defaultShell: String {
        if let envShell = ProcessInfo.processInfo.environment["SHELL"],
           FileManager.default.isExecutableFile(atPath: envShell) {
            return envShell
        }
        
        let candidateShells = ["/bin/zsh", "/bin/bash", "/usr/bin/zsh", "/usr/bin/bash"]
        for shell in candidateShells {
            if FileManager.default.isExecutableFile(atPath: shell) {
                return shell
            }
        }
        return "/bin/zsh"
    }
    
    public static func makeEnvironment(workingDirectory: URL? = nil) -> [String] {
        var env = ProcessInfo.processInfo.environment
        
        // Ensure standard macOS CLI paths are included so claude, gemini, npm, etc. are found
        let home = NSHomeDirectory()
        let standardPaths = [
            "\(home)/.gemini/antigravity-cli/bin",
            "\(home)/.local/bin",
            "\(home)/.cargo/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        
        var currentPaths = (env["PATH"] ?? "").components(separatedBy: ":").filter { !$0.isEmpty }
        for path in standardPaths {
            if !currentPaths.contains(path) && FileManager.default.fileExists(atPath: path) {
                currentPaths.append(path)
            }
        }
        
        // Also look for nvm node versions if present
        let nvmVersionsDir = "\(home)/.nvm/versions/node"
        if FileManager.default.fileExists(atPath: nvmVersionsDir),
           let contents = try? FileManager.default.contentsOfDirectory(atPath: nvmVersionsDir) {
            for version in contents.sorted().reversed() {
                let binPath = "\(nvmVersionsDir)/\(version)/bin"
                if FileManager.default.fileExists(atPath: binPath) && !currentPaths.contains(binPath) {
                    currentPaths.insert(binPath, at: 0)
                    break
                }
            }
        }
        
        env["PATH"] = currentPaths.joined(separator: ":")
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        
        if env["LANG"] == nil {
            env["LANG"] = "en_US.UTF-8"
        }
        if env["LC_ALL"] == nil {
            env["LC_ALL"] = "en_US.UTF-8"
        }
        if env["HOME"] == nil {
            env["HOME"] = home
        }
        if env["USER"] == nil {
            env["USER"] = NSUserName()
        }
        if env["SHELL"] == nil {
            env["SHELL"] = defaultShell
        }
        if let dir = workingDirectory {
            env["PWD"] = dir.path
        }
        
        return env.map { "\($0.key)=\($0.value)" }
    }
    
    // MARK: - Path Escaping & Drag-and-Drop Helpers
    
    /// Escapes special shell characters in a file or directory path so that it can be safely pasted into a shell command line.
    public static func escapePath(_ path: String) -> String {
        let charactersToEscape: Set<Character> = [
            " ", "\t", "\n", "\r",
            "\\", "'", "\"", "`",
            "$", "*", "?", "~", "#",
            "{", "}", "(", ")",
            "<", ">", "&", ";", "|",
            "!", "[", "]", "^"
        ]
        var result = ""
        result.reserveCapacity(path.count + 8)
        for char in path {
            if charactersToEscape.contains(char) {
                result.append("\\")
            }
            result.append(char)
        }
        return result
    }
    
    /// Formats an array of dropped URLs into an escaped, space-separated string suitable for insertion into a terminal shell.
    public static func formatDroppedURLs(_ urls: [URL]) -> String {
        guard !urls.isEmpty else { return "" }
        let formatted = urls.map { url -> String in
            let path = url.isFileURL ? url.path : url.absoluteString
            return escapePath(path)
        }.joined(separator: " ") + " "
        return formatted
    }
    
    /// Checks whether the dragging pasteboard contains readable file URLs, general URLs, or text strings.
    public static func canHandleDrag(pasteboard: NSPasteboard) -> Bool {
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
            return true
        }
        if let types = pasteboard.types {
            if types.contains(.fileURL) ||
               types.contains(.URL) ||
               types.contains(.string) ||
               types.contains(NSPasteboard.PasteboardType("NSFilenamesPboardType")) {
                return true
            }
        }
        return false
    }
    
    /// Extracts file URLs or generic URLs from the dragging pasteboard across modern and legacy pasteboard types.
    public static func extractURLs(from pasteboard: NSPasteboard) -> [URL] {
        // 1. Try reading standard NSURL objects with file URLs only option
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return urls
        }
        
        // 2. Try reading URLs from pasteboard items
        if let items = pasteboard.pasteboardItems {
            var urls: [URL] = []
            for item in items {
                if let urlString = item.string(forType: .fileURL) ?? item.string(forType: .URL),
                   let url = URL(string: urlString) {
                    urls.append(url)
                }
            }
            if !urls.isEmpty {
                return urls
            }
        }
        
        // 3. Try legacy NSFilenamesPboardType
        if let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String], !filenames.isEmpty {
            return filenames.map { URL(fileURLWithPath: $0) }
        }
        
        // 4. Try reading NSURL objects without options
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return urls
        }
        
        // 5. Try plain text that starts with file://
        if let text = extractString(from: pasteboard) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("file://"), let url = URL(string: trimmed) {
                return [url]
            }
        }
        
        return []
    }
    
    /// Extracts plain text from the dragging pasteboard.
    public static func extractString(from pasteboard: NSPasteboard) -> String? {
        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], let first = strings.first, !first.isEmpty {
            return first
        }
        if let str = pasteboard.string(forType: .string), !str.isEmpty {
            return str
        }
        return nil
    }
}
