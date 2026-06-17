import SwiftUI
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @AppStorage("scrollSpeed") var scrollSpeed: Double = 40
    @AppStorage("fontSize") var fontSize: Double = 56

    @Published var isPlaying = false
    @Published var isManualScrolling = false

    // MARK: - 文本行分析

    func computeLines(from script: String) -> [String] {
        let raw = script.components(separatedBy: "\n")
        var lines = raw
        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeFirst()
        }
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        guard !lines.isEmpty else { return [""] }
        return lines
    }

    func estimatedLineHeight(lineSpacingMultiplier: Double = 0.25) -> CGFloat {
        fontSize * (1.0 + lineSpacingMultiplier)
    }

    func scrollYForLine(
        _ index: Int,
        lines: [String],
        containerWidth: CGFloat,
        topPadding: CGFloat
    ) -> CGFloat {
        var y: CGFloat = topPadding
        for i in 0..<min(index, lines.count) {
            if i == index { break }
            let line = lines[i]
            let charWidth = fontSize * 0.6
            let effectiveWidth = max(containerWidth - 96, 100)
            let charsPerLine = max(Int(effectiveWidth / charWidth), 1)
            let displayLines = max(1, Int(ceil(Double(line.count) / Double(charsPerLine))))
            y += CGFloat(displayLines) * estimatedLineHeight()
        }
        return y
    }

    // MARK: - 播放控制

    func togglePlayPause() { isPlaying.toggle() }
    func pause() { isPlaying = false }

    func stop() {
        isPlaying = false
        isManualScrolling = false
    }
}
