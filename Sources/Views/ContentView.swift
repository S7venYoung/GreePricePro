import SwiftUI

// 定义辅助视图，用于访问底层 NSWindow (保持置顶功能)
struct WindowAccessor: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool
    func makeNSView(context: Context) -> NSView { let view = NSView(); DispatchQueue.main.async { if let window = view.window { context.coordinator.window = window; updateLevel(window: window, isTop: isAlwaysOnTop) } }; return view }
    func updateNSView(_ nsView: NSView, context: Context) { if let window = context.coordinator.window { updateLevel(window: window, isTop: isAlwaysOnTop) } }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { weak var window: NSWindow? }
    private func updateLevel(window: NSWindow, isTop: Bool) { window.level = isTop ? .floating : .normal }
}

struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var isPinned: Bool = false
    
    var body: some View {
        // 直接展示 CalculatorView，不再使用 NavigationSplitView
        CalculatorView(settings: settings)
            .background(WindowAccessor(isAlwaysOnTop: $isPinned))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { isPinned.toggle() }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .foregroundColor(isPinned ? .red : .primary)
                    }
                    .help(isPinned ? "取消置顶" : "窗口置顶")
                }
            }
    }
}
