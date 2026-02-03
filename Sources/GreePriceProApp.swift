import SwiftUI
import AppKit

@main
struct GreePriceProApp: App {
    init() { AppIconGenerator.applyBrandedIcon() }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 不设置任何 frame，让 SwiftUI 根据 ContentView 的大小自动决定窗口大小
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize) // 关键：窗口大小由内容决定
        
        MenuBarExtra("格力报价", systemImage: "yen.circle.fill") {
            Button("显示主面板") { NSApp.activate(ignoringOtherApps: true); if let window = NSApp.windows.first { window.makeKeyAndOrderFront(nil); window.deminiaturize(nil) } }
            Divider()
            Button("退出 App") { NSApplication.shared.terminate(nil) }
        }
    }
}

// 图标生成 (保持简化版)
struct AppIconGenerator {
    static func applyBrandedIcon() {
        let size = NSSize(width: 512, height: 512); let image = NSImage(size: size); image.lockFocus()
        NSColor(srgbRed: 229/255, green: 0/255, blue: 18/255, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 110, yRadius: 110).fill()
        let text = "¥" as NSString; let font = NSFont.systemFont(ofSize: 320, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        text.draw(at: NSPoint(x: (size.width - text.size(withAttributes: attrs).width)/2, y: (size.height - text.size(withAttributes: attrs).height)/2 + 20), withAttributes: attrs)
        let sub = "Pro" as NSString; let subF = NSFont.systemFont(ofSize: 80, weight: .bold); let subA = [.font: subF, .foregroundColor: NSColor.white.withAlphaComponent(0.9)] as [NSAttributedString.Key: Any]
        sub.draw(at: NSPoint(x: (size.width - sub.size(withAttributes: subA).width)/2, y: 60), withAttributes: subA)
        image.unlockFocus(); NSApplication.shared.applicationIconImage = image
    }
}
