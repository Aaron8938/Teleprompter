import SwiftUI

struct ContentView: View {
    @AppStorage("scriptText") var scriptText = ""
    @State private var showPlayer = false
    @StateObject private var playerVM = PlayerViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showPlayer {
                PlayerView(viewModel: playerVM, scriptText: scriptText, onExit: {
                    showPlayer = false
                })
            } else {
                editorView
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showPlayer)
    }

    private var editorView: some View {
        ZStack(alignment: .bottom) {
            // 全屏文本编辑器 — 无边距限制
            ZStack(alignment: .topLeading) {
                TextEditor(text: $scriptText)
                    .font(.system(size: 18))
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .foregroundStyle(.primary)

                if scriptText.isEmpty && !isFocused {
                    Text("Paste your script...")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea(edges: .top)

            // 悬浮液体玻璃开始按钮
            Button {
                guard !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                playerVM.stop()
                showPlayer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: 280)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: Capsule())
            .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
