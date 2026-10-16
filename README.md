# GridTerm ⚡️

A minimal, lightweight, native macOS desktop terminal workspace. Choose your grid layout and run multiple independent terminals in one window.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=flat&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0%2B-F05138?style=flat&logo=swift)
![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon%20%2F%20arm64-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Highlights

- **Native macOS Performance**: Built with Swift, SwiftUI, AppKit, and [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm). Super fast, responsive, and uses <40MB RAM.
- **Dynamic Grid Layouts**: Seamlessly switch between `1×1`, `1×2`, `2×1`, `2×2`, `2×3`, `2×4`, `3×3`, or any custom row/column matrix up to 5×5.
- **Preserved Sessions**: Changing layouts never kills your running processes or shell history. Sessions are kept alive in the background and restored when switching back.
- **Instant Focus Shortcuts**: Press `⌘1` through `⌘9` to immediately jump to and focus any terminal pane.
- **Proportional Resizing**: Interactive draggable dividers between rows and columns. Double-click dividers to equalize pane dimensions.
- **Full Shell & CLI Compatibility**: Uses your system shell (`/bin/zsh`, `/bin/bash`) with your complete login environment. Tools like `claude`, `gemini`, `codex`, `npm`, `git`, `python3`, and `brew` work out of the box.
- **100% Offline & Private**: Zero accounts, zero tracking, zero cloud services, zero analytics.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘1` ... `⌘9` | Instantly focus Terminal pane 1 through 9 |
| `⌘+` / `⌘=` | Zoom In (increase terminal font size) |
| `⌘-` | Zoom Out (decrease terminal font size) |
| `⌘0` | Reset font size to default (13pt) |
| `⌘K` | Clear active terminal screen |
| `⌘⌥1` ... `⌘⌥7` | Switch layout presets (`1×1`, `1×2`, `2×1`, `2×2`, `2×3`, `2×4`, `3×3`) |
| `⌘⇧M` | Toggle maximize / restore active pane |
| `⌘⇧R` | Restart active shell |
| `⌘⇧W` | Close active pane |
| `⌘C` / `⌘V` | Copy selection / Paste clipboard |

---

## 🚀 Quick Start

### Build & Run locally:

```bash
# Clone the repository
git clone https://github.com/bossgghere/multi-grid-terminal.git
cd multi-grid-terminal

# Run tests
swift test

# Build release and install to /Applications
./scripts/package_app.sh

# Launch the app
open /Applications/GridTerm.app
```

---

## 🛠 Project Structure

```
multi-grid-terminal/
├── Package.swift               # Swift Package definition
├── Sources/
│   ├── GridTerm/               # App entrypoint (AppKit + SwiftUI Scene)
│   └── GridTermKit/            # Core framework
│       ├── Models/             # GridLayout, TerminalSession
│       ├── Services/           # SessionManager, ShellEnvironment
│       └── Views/              # ResizableGridView, TerminalPaneView, ToolbarViews
├── Tests/
│   └── GridTermTests/          # Unit & integration test suite
└── scripts/
    ├── package_app.sh          # Builds release binary, creates GridTerm.app, and installs to /Applications
    ├── run_gridterm.sh         # Quick launch helper
    └── generate_icon.swift     # Generates AppIcon.icns
```

---

## 📄 License

MIT License. Free to use and distribute.
