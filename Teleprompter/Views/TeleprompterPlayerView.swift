import SwiftUI
import Combine

// MARK: - iOS 模糊视图
#if os(iOS)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif

// MARK: - 测量文字高度
private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - macOS 触控板滚轮捕获
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
                    Rectangle().fill(.clear).frame(height: topPadding)

                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.isEmpty ? " " : line)
                            .font(.system(size: viewModel.fontSize, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            #if os(iOS)
                            .padding(.horizontal, 0)
                            #else
                            .padding(.horizontal, 48)
                            #endif
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture { handleLineTap(index) }
                    }

                    Rectangle().fill(.clear).frame(height: geo.size.height)
                }
                .background(
                    GeometryReader { textGeo in
                        Color.clear.preference(key: TextHeightKey.self, value: textGeo.size.height)
                    }
                )
                .offset(y: -scrollY)
                .gesture(dragGesture)
            }
            #if os(iOS)
            .mask(edgeFadeMask)
            .ignoresSafeArea(.all)
            #else
            .clipped()
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

            // 进度条（macOS 右侧 / iOS 顶部）
            progressIndicator

            // iOS 顶部模糊过渡（灵动岛 / 状态栏区域）
            #if os(iOS)
            topBlurOverlay
            #endif

            // 控制栏
            controlsOverlay
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
            #if os(macOS)
            setBlackBackground()
            #endif
            viewModel.isPlaying = true
        }
        .onDisappear {
            #if os(macOS)
            restoreWhiteBackground()
            #endif
        }
        // 键盘快捷键 (macOS)
        .onKeyPress(.space) { viewModel.togglePlayPause(); return .handled }
        .onKeyPress(.escape) { exitPlayer(); return .handled }
        .onKeyPress(.upArrow) { viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150); return .handled }
        .onKeyPress(.downArrow) { viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5); return .handled }
        .onKeyPress(.leftArrow) { viewModel.fontSize = max(viewModel.fontSize - 4, 16); return .handled }
        .onKeyPress(.rightArrow) { viewModel.fontSize = min(viewModel.fontSize + 4, 120); return .handled }
    }

    // MARK: 进度条

    private var progressIndicator: some View {
        Group {
            if maxScrollY > 0 {
                #if os(macOS)
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
                #else
                // iOS: 顶部细线进度条
                VStack {
                    GeometryReader { geo in
                        Capsule()
                            .fill(.white.opacity(0.12))
                            .frame(height: 2)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.6))
                                    .frame(width: geo.size.width * progress, height: 2)
                            }
                    }
                    .frame(height: 2)
                    .padding(.top, 2)
                    Spacer()
                }
                .allowsHitTesting(false)
                #endif
            }
        }
    }

    // MARK: iOS 边缘模糊遮罩（用 mask 替代 clipped，文字自然淡入淡出）

    #if os(iOS)
    private var edgeFadeMask: some View {
        VStack(spacing: 0) {
            // 顶部淡入 — 从完全透明渐变到全白，柔化状态栏/灵动岛边缘
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)

            // 下方全部全白 = 完全可见，铺满到底
            Rectangle().fill(.white)
        }
    }
    #endif

    // MARK: iOS 顶部模糊过渡

    #if os(iOS)
    private var topBlurOverlay: some View {
        VStack {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(0.85), location: 0.3),
                    .init(color: .black.opacity(0.4), location: 0.7),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .ignoresSafeArea(edges: .top)
            Spacer()
        }
        .allowsHitTesting(false)
    }
    #endif

    // MARK: 控制栏浮层

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            #if os(iOS)
            iOSControlBar
            #else
            macOSControlBar
            #endif
        }
    }

    // MARK: - macOS 控制栏

    private var macOSControlBar: some View {
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
                .font(.caption.monospacedDigit()).foregroundStyle(.white).frame(width: 28)

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
                .foregroundStyle(.white).frame(width: 32)

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
                    scrollY = 0; currentLineIndex = 0
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
        .padding(.horizontal, 12).padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20).padding(.bottom, 32)
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 6)
    }

    // MARK: - iOS 控制栏（Apple Music 风格液态玻璃）

    private var iOSControlBar: some View {
        HStack(spacing: 0) {
            // 退出
            Button { exitPlayer() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 字号 -
            Button { viewModel.fontSize = max(viewModel.fontSize - 4, 16) } label: {
                Image(systemName: "textformat.size.smaller")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("\(Int(viewModel.fontSize))")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 28)

            Button { viewModel.fontSize = min(viewModel.fontSize + 4, 120) } label: {
                Image(systemName: "textformat.size.larger")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 速度 -
            Button { viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5) } label: {
                Image(systemName: "minus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("\(Int(viewModel.scrollSpeed))")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 28)

            Button { viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150) } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 播放/暂停
            Button {
                if !viewModel.isPlaying && scrollY >= maxScrollY && maxScrollY > 0 {
                    scrollY = 0; currentLineIndex = 0
                }
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 12)
        // 贴底，无多余留白；顶部留给状态栏/灵动岛
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

    // MARK: 行跳转

    private func handleLineTap(_ index: Int) {
        // iOS: 仅多行时支持点击跳转，单行不响应（避免整屏点击跳到开头）
        #if os(iOS)
        guard lines.count > 1 else { return }
        #endif
        jumpToLine(index)
    }

    private func jumpToLine(_ index: Int) {
        guard index < lines.count else { return }
        let containerWidth = viewWidth > 0 ? viewWidth - 96 : 400
        let targetY = viewModel.scrollYForLine(
            index, lines: lines, containerWidth: containerWidth, topPadding: topPadding
        )
        let adjustedY = max(0, min(targetY - viewHeight * 0.15, maxScrollY))
        withAnimation(.easeOut(duration: 0.35)) {
            scrollY = adjustedY
        }
        currentLineIndex = index
        viewModel.isManualScrolling = false
    }

    // MARK: 退出

    private func exitPlayer() {
        viewModel.stop()
        scrollY = 0
        #if os(macOS)
        restoreWhiteBackground()
        #endif
        onExit?()
    }

    // MARK: macOS 窗口背景

    #if os(macOS)
    private func setBlackBackground() {
        guard let window = NSApplication.shared.windows.first(
            where: { $0.isKeyWindow }
        ) ?? NSApplication.shared.keyWindow
        else { return }
        window.backgroundColor = .black
    }

    private func restoreWhiteBackground() {
        guard let window = NSApplication.shared.windows.first(
            where: { $0.isKeyWindow }
        ) ?? NSApplication.shared.keyWindow
        else { return }
        window.backgroundColor = NSColor(white: 0.97, alpha: 1)
    }
    #endif
}
