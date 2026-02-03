import SwiftUI

// 辅助视图：WindowAccessor (保持不变)
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
    @State private var selection: Panel? = .calculator
    @State private var isPinned: Bool = false
    
    enum Panel: Hashable { case calculator, productList, settings }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("智能报价", systemImage: "function").tag(Panel.calculator)
                Label("产品清单", systemImage: "list.bullet.rectangle").tag(Panel.productList)
                Divider()
                Label("参数配置", systemImage: "gearshape").tag(Panel.settings)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch selection {
            case .calculator: CalculatorView(settings: settings)
            case .productList: ProductListView()
            case .settings: SettingsView(settings: settings)
            case .none: Text("请选择功能")
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { isPinned.toggle() }) { Image(systemName: isPinned ? "pin.fill" : "pin").foregroundColor(isPinned ? .red : .primary) }
                .help(isPinned ? "取消置顶" : "窗口置顶")
            }
        }
        .background(WindowAccessor(isAlwaysOnTop: $isPinned))
    }
}
