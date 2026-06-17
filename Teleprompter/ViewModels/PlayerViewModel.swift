import SwiftUI
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    // 持久化设置
    @AppStorage("scrollSpeed") var scrollSpeed: Double = 40
    @AppStorage("fontSize") var fontSize: Double = 56

    @Published var isPlaying = false
    @Published var countdownRemaining: Int = 0

    private var countdownTask: Task<Void, Never>?

    func togglePlayPause() { isPlaying.toggle() }
    func pause() { isPlaying = false }

    func stop() {
        isPlaying = false
        countdownRemaining = 0
        countdownTask?.cancel()
    }

    func startCountdown() {
        countdownTask?.cancel()
        countdownRemaining = 3
        countdownTask = Task {
            for i in stride(from: 3, through: 1, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                countdownRemaining = i - 1
            }
            if Task.isCancelled { return }
            isPlaying = true
        }
    }
}
