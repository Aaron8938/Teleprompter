import SwiftUI

struct ContentView: View {
    @AppStorage("scriptText") var scriptText = ""
    @State private var showPlayer = false
    @StateObject private var playerVM = PlayerViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
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
        .onAppear { setupWindow() }
    }

    // MARK: - 背景

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

    // MARK: - 编辑器

    private var editorView: some View {
        ZStack(alignment: .bottom) {
            #if os(macOS)
            CenteredTextEditor(text: $scriptText)
                .ignoresSafeArea(.all)
            #else
            TextEditor(text: $scriptText)
                .font(.system(size: 20, design: .serif))
                .lineSpacing(8)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color(white: 0.2))
                .ignoresSafeArea(edges: .bottom)
                .scrollDismissesKeyboard(.interactively)
                .focused($isFocused)
                .toolbar { keyboardToolbar }
            #endif

            // 占位文字
            if scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isFocused {
                placeholderContent.allowsHitTesting(false)
            }

            // 开始按钮 — 键盘弹出时隐藏
            #if os(iOS)
            if !isFocused {
                startButton.padding(.bottom, 30)
            }
            #else
            startButton.padding(.bottom, 30)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - iOS 键盘工具栏（液态玻璃胶囊）

    #if os(iOS)
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                dismissKeyboard()
                if !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    playerVM.stop()
                    showPlayer = true
                }
            } label: {
                Text("Start")
                    .font(.body.weight(.semibold))
            }
            .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer()
            Button("Done") {
                dismissKeyboard()
            }
            .font(.body.weight(.bold))
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
    #endif

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

    // MARK: - 开始按钮

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
        .opacity(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
        .animation(.easeOut(duration: 0.25), value: scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - 窗口配置

    private func setupWindow() {
        #if os(macOS)
        guard let window = NSApplication.shared.windows.first else { return }
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(white: 0.97, alpha: 1)
        window.isMovableByWindowBackground = true
        #endif
    }
}
