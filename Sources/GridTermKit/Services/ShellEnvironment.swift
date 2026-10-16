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
}
