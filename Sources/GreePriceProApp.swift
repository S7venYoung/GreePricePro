import SwiftUI
import AppKit

@main
struct GreePriceProApp: App {
    init() {
        AppIconGenerator.applyBrandedIcon()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 【核心修改】
                // 1. 移除 width: 500 这种强制固定
                // 2. 设定 minWidth 保证界面不崩坏 (侧边栏220 + 计算器460 = 680)
                // 3. 设定 idealWidth 让窗口启动时刚好包裹内容，没有留白
                .frame(minWidth: 680, idealWidth: 680, maxWidth: .infinity,
                       minHeight: 650, idealHeight: 720, maxHeight: .infinity)
        }
        .windowStyle(.titleBar)
        // 让窗口大小根据内容偏好进行初始化
        .windowResizability(.contentSize)
        
        MenuBarExtra("格力报价", systemImage: "yen.circle.fill") {
            Button("显示主面板") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.deminiaturize(nil)
                }
            }
            Divider()
            Button("退出 App") { NSApplication.shared.terminate(nil) }
        }
    }
}

// 图标生成逻辑 (保持不变)
struct AppIconGenerator {
    static func applyBrandedIcon() {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size)
        image.lockFocus()
        let greeRed = NSColor(srgbRed: 229/255, green: 0/255, blue: 18/255, alpha: 1.0)
        greeRed.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 110, yRadius: 110).fill()
        let text = "¥" as NSString
        let font = NSFont.systemFont(ofSize: 320, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let textSize = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (size.width - textSize.width)/2, y: (size.height - textSize.height)/2 + 20), withAttributes: attrs)
        let subText = "Pro" as NSString
        let subFont = NSFont.systemFont(ofSize: 80, weight: .bold)
        let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: NSColor.white.withAlphaComponent(0.9)]
        let subSize = subText.size(withAttributes: subAttrs)
        subText.draw(at: NSPoint(x: (size.width - subSize.width)/2, y: 60), withAttributes: subAttrs)
        image.unlockFocus()
        NSApplication.shared.applicationIconImage = image
    }
}
