import SwiftUI

// WindowAccessor (保持不变)
struct WindowAccessor: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool
    func makeNSView(context: Context) -> NSView { let view = NSView(); DispatchQueue.main.async { if let window = view.window { context.coordinator.window = window; setupWindow(window); updateLevel(window: window, isTop: isAlwaysOnTop) } }; return view }
    func updateNSView(_ nsView: NSView, context: Context) { if let window = context.coordinator.window { updateLevel(window: window, isTop: isAlwaysOnTop) } }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { weak var window: NSWindow? }
    private func setupWindow(_ window: NSWindow) { window.isOpaque = false; window.backgroundColor = .clear; window.titlebarAppearsTransparent = true; window.isMovableByWindowBackground = true }
    private func updateLevel(window: NSWindow, isTop: Bool) { window.level = isTop ? .floating : .normal }
}

struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var isPinned: Bool = false
    
    var body: some View {
        // 【核心修改】将 isPinned 绑定传给 CalculatorView
        CalculatorView(settings: settings, isPinned: $isPinned)
            .background(WindowAccessor(isAlwaysOnTop: $isPinned))
            // 之前的 .toolbar 代码已经没用了，因为标题栏被隐藏了，所以删掉
    }
}
