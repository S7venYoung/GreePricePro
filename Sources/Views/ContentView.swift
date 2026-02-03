# 重写 ContentView.swift，加入置顶功能
import SwiftUI
import AppKit

// 1. 定义一个辅助视图，用于访问底层 NSWindow
struct WindowAccessor: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            // 视图加载完成后获取窗口对象
            if let window = view.window {
                context.coordinator.window = window
                updateLevel(window: window, isTop: isAlwaysOnTop)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // 当 State 变化时更新窗口层级
        if let window = context.coordinator.window {
            updateLevel(window: window, isTop: isAlwaysOnTop)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var window: NSWindow?
    }

    private func updateLevel(window: NSWindow, isTop: Bool) {
        // .floating = 置顶层级, .normal = 普通层级
        window.level = isTop ? .floating : .normal
    }
}

// 2. 更新主视图
struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var selection: Panel? = .calculator
    @State private var isPinned: Bool = false // 控制置顶状态
    
    enum Panel: Hashable {
        case calculator
        case productList
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: \$selection) {
                Label("智能报价计算", systemImage: "function")
                    .tag(Panel.calculator)
                
                Label("产品清单", systemImage: "list.bullet.rectangle")
                    .tag(Panel.productList)
                
                Divider()
                
                Label("参数配置", systemImage: "gearshape")
                    .tag(Panel.settings)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch selection {
            case .calculator:
                CalculatorView(settings: settings)
            case .productList:
                ProductListView()
            case .settings:
                SettingsView(settings: settings)
            case .none:
                Text("请选择功能")
            }
        }
        // 3. 添加工具栏按钮
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isPinned.toggle()
                }) {
                    // 根据状态改变图标颜色或样式
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .foregroundColor(isPinned ? .red : .primary)
                }
                .help(isPinned ? "取消置顶" : "窗口置顶")
            }
        }
        // 4. 注入窗口控制逻辑
        .background(WindowAccessor(isAlwaysOnTop: \$isPinned))
    }
}
