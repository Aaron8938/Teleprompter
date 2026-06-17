# Teleprompter

A clean, cross-platform teleprompter app for iOS and macOS built with SwiftUI.

## Features

- **Script Editor** — paste or type your script with full-screen editing
- **Smooth Scrolling** — 60fps auto-scroll playback with adjustable speed
- **3-2-1 Countdown** — animated countdown before playback starts
- **Progress Bar** — subtle vertical indicator showing reading progress
- **Adjustable Font Size** — 16pt to 120pt, persisted across app launches
- **Playback Controls** — play/pause, speed, font size all in a glass-effect toolbar
- **Keyboard Shortcuts** — full control without touching the mouse (Space, Escape, Arrow keys)
- **Auto-Save** — your script is automatically saved and restored

| Key | Action |
|-----|--------|
| Space | Toggle play/pause |
| Escape | Exit to editor |
| ↑ / ↓ | Adjust scroll speed |
| ← / → | Adjust font size |

## Requirements

- Xcode 26.5+
- iOS 26.5+ / macOS 26.5+
- Swift 5.0

## Project Structure

```
Teleprompter/
├── TeleprompterApp.swift          # @main entry point
├── ContentView.swift              # Script editor
├── AppIconProvider.swift          # macOS icon fix (conditional)
├── Views/
│   └── TeleprompterPlayerView.swift   # Player UI
├── ViewModels/
│   └── PlayerViewModel.swift          # Playback state & settings
└── Assets.xcassets/               # App icons & colors
```

## License

MIT
