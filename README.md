# Teleprompter

A clean, cross-platform teleprompter app for iOS and macOS built with SwiftUI.

## Features

| Feature | macOS | iOS |
|---------|-------|-----|
| Script Editor | ✅ CenteredTextEditor (NSTextView) | ✅ TextEditor + keyboard toolbar |
| Keyboard Toolbar | — | "Done" dismiss + "Start" enter player |
| Playback Start | Immediate | Immediate (or from keyboard toolbar) |
| Progress Bar | Right-side vertical capsule | Top thin line |
| Control Bar | Glass capsule, compact layout | Apple Music-style wide Capsule |
| Top Area | fullSizeContentView, transparent titlebar | Gradient + fade mask blending into status bar |
| Line Navigation | Tap to jump | Tap to jump (multi-line only) |
| Manual Scrolling | Trackpad wheel / drag | Touch drag |
| Font Size | 16-120pt (Arrow keys) | 16-120pt |
| Scroll Speed | 5-150 (Arrow keys) | 5-150 |
| Auto-Save | @AppStorage | @AppStorage |
| macOS Native | hiddenTitleBar, movableByWindowBackground | — |

## Keyboard Shortcuts (macOS)

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
├── CenteredTextEditor.swift       # macOS native text editor
├── AppIconProvider.swift          # macOS icon fix (conditional)
├── Views/
│   └── TeleprompterPlayerView.swift   # Player UI
├── ViewModels/
│   └── PlayerViewModel.swift          # Playback state & settings
└── Assets.xcassets/               # App icons & colors
```

## License

MIT
