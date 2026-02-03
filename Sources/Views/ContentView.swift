import SwiftUI

// WindowAccessor 用于置顶功能 (保持不变)
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
        // 【核心修改】只放 CalculatorView，不放 SplitView
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
            // 这里不加 frame，尺寸完全由 CalculatorView 撑开
    }
}
