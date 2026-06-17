import SwiftUI
import Combine

// MARK: - 测量文字高度
private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - macOS 触控板/鼠标滚轮事件捕获
#if os(macOS)
struct ScrollWheelCapture: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> ScrollWheelView {
        let view = ScrollWheelView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollWheelView, context: Context) {
        nsView.onScroll = onScroll
    }

    final class ScrollWheelView: NSView {
        var onScroll: ((CGFloat) -> Void)?

        override func scrollWheel(with event: NSEvent) {
            onScroll?(event.deltaY)
        }
    }
}
#endif

// MARK: - 播放器视图
struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    let scriptText: String
    var onExit: (() -> Void)?

    // MARK: 滚动状态
    @State private var scrollY: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var dragStartScrollY: CGFloat = 0

    // MARK: 行数据
    @State private var lines: [String] = []
    @State private var currentLineIndex: Int = 0

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    // MARK: 计算属性

    private var topPadding: CGFloat { max(viewHeight * 0.6, 100) }

    private var maxScrollY: CGFloat {
        guard textHeight > 1, viewHeight > 0 else { return 0 }
        return max(textHeight - viewHeight * 0.4, 0)
    }

    private var progress: Double {
        guard maxScrollY > 0 else { return 0 }
        return min(Double(scrollY / maxScrollY), 1.0)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)

            // 文字层
            GeometryReader { geo in

                VStack(spacing: viewModel.fontSize * 0.25) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: topPadding)

                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.isEmpty ? " " : line)
                            .font(.system(size: viewModel.fontSize, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 48)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                jumpToLine(index)
                            }
                    }

                    Rectangle()
                        .fill(.clear)
                        .frame(height: geo.size.height)
                }
                .background(
                    GeometryReader { textGeo in
                        Color.clear.preference(
                            key: TextHeightKey.self,
                            value: textGeo.size.height
                        )
                    }
                )
                .offset(y: -scrollY)
                .gesture(dragGesture)
            }
            .clipped()
            #if os(iOS)
            // iOS: 尊重顶部安全区（状态栏/灵动岛），底部留空间给控制栏
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
            #else
            // macOS: 铺满整个窗口
            .ignoresSafeArea(.all)
            #endif
            .allowsHitTesting(true)
            #if os(macOS)
            .overlay(
                ScrollWheelCapture { delta in
                    guard !viewModel.isPlaying else { return }
                    scrollY = max(0, min(scrollY - delta * 3.0, maxScrollY))
                }
            )
            #endif
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { viewHeight = $0 }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { viewWidth = $0 }
            .onPreferenceChange(TextHeightKey.self) { textHeight = $0 }

            // 进度条
            if maxScrollY > 0 {
                HStack {
                    Spacer()
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(width: 3, height: viewHeight * 0.4)
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(.white.opacity(0.55))
                                .frame(width: 3, height: viewHeight * 0.4 * progress)
                        }
                        .padding(.trailing, 12)
                        .offset(y: -20)
                }
                .allowsHitTesting(false)
            }

            // 底部控制栏
            VStack {
                Spacer()
                bottomBar
            }
        }
        .onReceive(timer) { _ in
            guard viewModel.isPlaying, !viewModel.isManualScrolling else { return }
            scrollY += viewModel.scrollSpeed / 60.0
            if maxScrollY > 0 && scrollY >= maxScrollY {
                scrollY = maxScrollY
                viewModel.pause()
            }
        }
        .onAppear {
            lines = viewModel.computeLines(from: scriptText)
            scrollY = 0
            textHeight = 0
            currentLineIndex = 0
            viewModel.stop()
            setBlackBackground()
            viewModel.isPlaying = true
        }
        .onDisappear {
            restoreWhiteBackground()
        }
        // 键盘快捷键
        .onKeyPress(.space) { viewModel.togglePlayPause(); return .handled }
        .onKeyPress(.escape) { exitPlayer(); return .handled }
        .onKeyPress(.upArrow) { viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150); return .handled }
        .onKeyPress(.downArrow) { viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5); return .handled }
        .onKeyPress(.leftArrow) { viewModel.fontSize = max(viewModel.fontSize - 4, 16); return .handled }
        .onKeyPress(.rightArrow) { viewModel.fontSize = min(viewModel.fontSize + 4, 120); return .handled }
    }

    // MARK: 拖拽手势（暂停时可拖动）

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard !viewModel.isPlaying else { return }
                if !viewModel.isManualScrolling {
                    dragStartScrollY = scrollY
                    viewModel.isManualScrolling = true
                }
                let newY = dragStartScrollY - value.translation.height
                scrollY = max(0, min(newY, maxScrollY))
            }
            .onEnded { _ in
                viewModel.isManualScrolling = false
            }
    }

    // MARK: 行跳转（暂停时不自动播放）

    private func jumpToLine(_ index: Int) {
        guard index < lines.count else { return }
        let containerWidth = viewWidth > 0 ? viewWidth - 96 : 400
        let targetY = viewModel.scrollYForLine(
            index,
            lines: lines,
            containerWidth: containerWidth,
            topPadding: topPadding
        )
        let adjustedY = max(0, min(targetY - viewHeight * 0.15, maxScrollY))
        withAnimation(.easeOut(duration: 0.35)) {
            scrollY = adjustedY
        }
        currentLineIndex = index
        viewModel.isManualScrolling = false
        // 暂停时不自动播放，播放中保持不变
    }

    // MARK: 退出

    private func exitPlayer() {
        viewModel.stop()
        scrollY = 0
        restoreWhiteBackground()
        onExit?()
    }

    // MARK: 窗口背景切换（fullSizeContentView 已由 ContentView 设置）

    private func setBlackBackground() {
        #if os(macOS)
        guard let window = NSApplication.shared.windows.first(
            where: { $0.isKeyWindow }
        ) ?? NSApplication.shared.keyWindow
        else { return }
        window.backgroundColor = .black
        #endif
    }

    private func restoreWhiteBackground() {
        #if os(macOS)
        guard let window = NSApplication.shared.windows.first(
            where: { $0.isKeyWindow }
        ) ?? NSApplication.shared.keyWindow
        else { return }
        window.backgroundColor = NSColor(white: 0.97, alpha: 1)
        #endif
    }

    // MARK: 底部控制栏

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { exitPlayer() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            separator

            Button { viewModel.fontSize = max(viewModel.fontSize - 4, 16) } label: {
                Image(systemName: "textformat.size.smaller")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("\(Int(viewModel.fontSize))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 28)

            Button { viewModel.fontSize = min(viewModel.fontSize + 4, 120) } label: {
                Image(systemName: "textformat.size.larger")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            separator

            Button { viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5) } label: {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("\(Int(viewModel.scrollSpeed))")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 32)

            Button { viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150) } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            separator

            Button {
                if !viewModel.isPlaying && scrollY >= maxScrollY && maxScrollY > 0 {
                    scrollY = 0
                    currentLineIndex = 0
                }
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20)
        #if os(iOS)
        .padding(.bottom, 8)
        #else
        .padding(.bottom, 32)
        #endif
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 6)
    }
}
