import SwiftUI

struct ContentView: View {
    @StateObject var settings = AppSettings()
    @State private var selection: Panel? = .calculator
    
    enum Panel: Hashable {
        case calculator
        case productList
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
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
    }
}
