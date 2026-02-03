import SwiftUI

// MARK: - 稳健版 WindowAccessor
// 使用自定义 NSView 精确监听窗口挂载事件，解决置顶失效问题
struct WindowAccessor: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool
    
    func makeNSView(context: Context) -> WindowTrackingView {
        let view = WindowTrackingView()
        // 当视图挂载到窗口时触发的回调
        view.onWindowAttached = { window in
            setupWindow(window)
            updateLevel(window: window, isTop: isAlwaysOnTop)
        }
        return view
    }
    
    func updateNSView(_ nsView: WindowTrackingView, context: Context) {
        // 当 SwiftUI 状态改变时，直接通过 nsView 获取当前窗口更新层级
        if let window = nsView.window {
            updateLevel(window: window, isTop: isAlwaysOnTop)
        }
    }
    
    private func setupWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        // 确保窗口能覆盖全屏应用（可选，增强置顶体验）
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    private func updateLevel(window: NSWindow, isTop: Bool) {
        window.level = isTop ? .floating : .normal
    }
}

// 核心：自定义 NSView 子类，生命周期更可控
class WindowTrackingView: NSView {
    var onWindowAttached: ((NSWindow) -> Void)?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            onWindowAttached?(window)
        }
    }
}

struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var isPinned: Bool = false
    
    var body: some View {
        CalculatorView(settings: settings, isPinned: $isPinned)
            .background(WindowAccessor(isAlwaysOnTop: $isPinned))
    }
}
