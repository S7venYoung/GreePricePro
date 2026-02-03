import SwiftUI

// 增强版 WindowAccessor：负责去背景、支持拖拽
struct WindowAccessor: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.window = window
                setupWindow(window) // 初始化窗口样式
                updateLevel(window: window, isTop: isAlwaysOnTop)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = context.coordinator.window {
            updateLevel(window: window, isTop: isAlwaysOnTop)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { weak var window: NSWindow? }
    
    // 【核心】设置窗口为纯透明，且可拖拽
    private func setupWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        // 允许用户按住背景任意位置移动窗口（替代标题栏拖拽）
        window.isMovableByWindowBackground = true 
    }
    
    private func updateLevel(window: NSWindow, isTop: Bool) {
        window.level = isTop ? .floating : .normal
    }
}

struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var isPinned: Bool = false
    
    var body: some View {
        CalculatorView(settings: settings)
            // 注入透明窗口控制器
            .background(WindowAccessor(isAlwaysOnTop: $isPinned))
            // 既然没了标题栏，我们在 View 内部给一个置顶按钮
            // 注意：Traffic Lights（红绿灯）默认会浮在左上角
    }
}
