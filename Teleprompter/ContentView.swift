import SwiftUI

struct ContentView: View {
    @AppStorage("scriptText") var scriptText = ""
    @State private var showPlayer = false
    @StateObject private var playerVM = PlayerViewModel()
    @State private var isFocused = false

    var body: some View {
        ZStack {
            // 背景渐变
            editorBackground
                .ignoresSafeArea(.all)

            if showPlayer {
                PlayerView(viewModel: playerVM, scriptText: scriptText, onExit: {
                    showPlayer = false
                })
                .transition(.opacity)
            } else {
                editorView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPlayer)
        .onAppear {
            setupWindow()
        }
    }

    // MARK: - 编辑器背景

    private var editorBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color(white: 0.96), location: 0),
                .init(color: Color(white: 0.99), location: 0.5),
                .init(color: .white, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 编辑器主体

    private var editorView: some View {
        ZStack(alignment: .bottom) {
            #if os(macOS)
            CenteredTextEditor(text: $scriptText)
                .ignoresSafeArea(.all)
            #else
            ZStack(alignment: .center) {
                TextEditor(text: $scriptText)
                    .font(.system(size: 20, design: .serif))
                    .lineSpacing(8)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color(white: 0.2))

                if scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    placeholderContent
                }
            }
            .ignoresSafeArea(.all)
            #endif

            // 占位文字（macOS 用 overlay 方式）
            #if os(macOS)
            if scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                placeholderContent
                    .allowsHitTesting(false)
            }
            #endif

            // 开始按钮
            startButton
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 占位内容

    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.quote")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color(white: 0.55))
            Text("Paste or type your script here...")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(white: 0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 开始按钮（液态玻璃，全控件可点击）

    private var startButton: some View {
        Button {
            guard !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            playerVM.stop()
            showPlayer = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Start")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(width: 260, height: 48)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Capsule())
        .scaleEffect(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.96 : 1.0)
        .opacity(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
        .animation(.easeOut(duration: 0.25), value: scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - 窗口配置

    private func setupWindow() {
        #if os(macOS)
        guard let window = NSApplication.shared.windows.first else { return }
        // .hiddenTitleBar 已处理 fullSizeContentView + transparent titlebar
        // 只需微调外观
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(white: 0.97, alpha: 1)
        window.isMovableByWindowBackground = true
        #endif
    }
}

#Preview {
    ContentView()
}
