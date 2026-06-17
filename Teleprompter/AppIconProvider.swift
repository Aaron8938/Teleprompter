#if os(macOS)
import AppKit

enum AppIconProvider {
    /// 强制从 Bundle 加载 .icns 并以编程方式设置为应用图标
    /// 绕开 Launch Services 缓存，解决台前调度（Stage Manager）显示旧图标的问题
    static func applyApplicationIcon() {
        let iconName = (Bundle.main.infoDictionary?["CFBundleIconFile"] as? String) ?? "Teleprompter"

        if let iconURL = Bundle.main.url(forResource: iconName, withExtension: "icns")
                      ?? Bundle.main.url(forResource: iconName, withExtension: nil),
           let image = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = image
        } else {
            NSApplication.shared.applicationIconImage = nil
        }

        // 清除 Dock 自定义内容，让系统用 applicationIconImage
        NSApplication.shared.dockTile.contentView = nil
        NSApplication.shared.dockTile.badgeLabel = nil
        NSApplication.shared.dockTile.display()
    }
}
#endif
