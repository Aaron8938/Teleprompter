import SwiftUI
import Combine

// 测量文字实际高度
private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    let scriptText: String
    var onExit: (() -> Void)?

    @State private var scrollY: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var topPadding: CGFloat { max(viewHeight * 0.6, 100) }
    private var maxScrollY: CGFloat {
        guard textHeight > 1, viewHeight > 0 else { return 0 }
        return max(textHeight + topPadding - viewHeight * 0.4, 0)
    }
    private var progress: Double {
        guard maxScrollY > 0 else { return 0 }
        return min(Double(scrollY / maxScrollY), 1.0)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 文字层
            GeometryReader { geo in
                let topPad = max(geo.size.height * 0.6, 100)

                ZStack(alignment: .trailing) {
                    // 滚动文字
                    VStack(spacing: 0) {
                        Text(scriptText)
                            .font(.system(size: viewModel.fontSize, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(viewModel.fontSize * 0.25)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: geo.size.width - 96)
                            .background(
                                GeometryReader { textGeo in
                                    Color.clear.preference(
                                        key: TextHeightKey.self,
                                        value: textGeo.size.height
                                    )
                                }
                            )
                            .padding(.top, topPad)

                        Rectangle().fill(.clear).frame(height: geo.size.height)
                    }
                    .offset(y: -scrollY)

                    // 进度条
                    if maxScrollY > 0 {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(width: 3, height: geo.size.height * 0.3)
                            .overlay(alignment: .top) {
                                Capsule()
                                    .fill(.white.opacity(0.7))
                                    .frame(width: 3, height: geo.size.height * 0.3 * progress)
                            }
                            .padding(.trailing, 10)
                    }
                }
                .clipped()
            }
            .allowsHitTesting(false)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { newHeight in
                viewHeight = newHeight
            }
            .onPreferenceChange(TextHeightKey.self) { h in
                textHeight = h
            }

            // 倒计时
            if viewModel.countdownRemaining > 0 {
                Text("\(viewModel.countdownRemaining)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeOut(duration: 0.3), value: viewModel.countdownRemaining)
            }

            // 底部控制栏（包含退出按钮，所有控件融合在一起）
            VStack {
                Spacer()
                bottomBar
            }
        }
        .onReceive(timer) { _ in
            guard viewModel.isPlaying else { return }
            scrollY += viewModel.scrollSpeed / 60.0
            if maxScrollY > 0 && scrollY >= maxScrollY {
                scrollY = maxScrollY
                viewModel.pause()
            }
        }
        .onAppear {
            scrollY = 0
            textHeight = 0
            viewModel.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.startCountdown()
            }
        }
        .onKeyPress(.space) { viewModel.togglePlayPause(); return .handled }
        .onKeyPress(.escape) { viewModel.stop(); scrollY = 0; onExit?(); return .handled }
        .onKeyPress(.upArrow) { viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150); return .handled }
        .onKeyPress(.downArrow) { viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5); return .handled }
        .onKeyPress(.leftArrow) { viewModel.fontSize = max(viewModel.fontSize - 4, 16); return .handled }
        .onKeyPress(.rightArrow) { viewModel.fontSize = min(viewModel.fontSize + 4, 120); return .handled }
    }

    // MARK: - 底部控制栏 — 退出 + 字号 + 速度 + 播放，全部融合在一个玻璃圆角矩形

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // 退出
            Button {
                viewModel.stop()
                scrollY = 0
                onExit?()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("退出")

            // 分隔线
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 6)

            // 字号控制
            Button {
                viewModel.fontSize = max(viewModel.fontSize - 4, 16)
            } label: {
                Image(systemName: "textformat.size.smaller")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("减小字号")

            Text("\(Int(viewModel.fontSize))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 28)

            Button {
                viewModel.fontSize = min(viewModel.fontSize + 4, 120)
            } label: {
                Image(systemName: "textformat.size.larger")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("增大字号")

            // 分隔线
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 6)

            // 速度控制
            Button {
                viewModel.scrollSpeed = max(viewModel.scrollSpeed - 5, 5)
            } label: {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("减速")

            Text("\(Int(viewModel.scrollSpeed))")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 32)

            Button {
                viewModel.scrollSpeed = min(viewModel.scrollSpeed + 5, 150)
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("加速")

            // 分隔线
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 6)

            // 播放/暂停
            Button {
                if !viewModel.isPlaying && scrollY >= maxScrollY && maxScrollY > 0 {
                    scrollY = 0
                }
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isPlaying ? "暂停" : "播放")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}
