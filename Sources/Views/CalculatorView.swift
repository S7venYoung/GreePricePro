import SwiftUI

// MARK: - 风格修饰符
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20 //稍微减小一点圆角，更贴合窗口
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            // 移除阴影，因为现在卡片就是窗口本身，窗口系统自带阴影
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }
}
extension View { func liquidGlassStyle(cornerRadius: CGFloat = 20) -> some View { modifier(LiquidGlassCard(cornerRadius: cornerRadius)) } }

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    @State private var priceInput: Double? = nil
    @State private var groupDiscountInput: Double? = nil
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    @State private var showSettings = false
    
    let gridColumns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            // === 主内容 ===
            HStack(spacing: 0) {
                
                // === 左侧 ===
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 【核心修改】增加顶部留白，给红绿灯(Traffic Lights)腾出位置
                    // macOS 红绿灯高度大约是 20-30pt
                    Spacer().frame(height: 32)
                    
                    VStack(spacing: 10) {
                        InputCard(title: "官方指导价", value: $priceInput, color: .primary)
                        InputCard(title: "团购优惠", value: $groupDiscountInput, color: .indigo)
                    }
                    Divider().overlay(Color.black.opacity(0.05))
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("机型档次", systemImage: "air.conditioner.horizontal").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(ProductTier.allCases) { tier in
                                    GlassButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .blue) { withAnimation(.snappy) { selectedTier = tier } }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Label("销售渠道", systemImage: "network").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(ChannelType.allCases) { channel in
                                    GlassButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) { withAnimation(.snappy) { selectedChannel = channel } }
                                }
                            }
                        }
                    }
                    Spacer() // 底部填充
                }
                .padding(20)
                .frame(width: 230)
                
                // 分割线
                Rectangle().fill(LinearGradient(colors: [.clear, .black.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)).frame(width: 1).padding(.vertical, 0)
                
                // === 右侧 ===
                VStack(spacing: 0) {
                    let result = PriceCalculator.calculate(originalPrice: priceInput ?? 0, groupDiscountInput: groupDiscountInput ?? 0, tier: selectedTier, channel: selectedChannel, settings: settings)
                    let profitMargin = result.subsidyPrice > 0 ? result.actualProfit / result.subsidyPrice : 0
                    
                    // 右侧顶部也稍微加点留白保持对齐，或者利用Spacer
                    Spacer().frame(height: 32)

                    VStack(spacing: 6) {
                        HStack {
                            Text("国补后基准").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text(result.subsidyPrice, format: .currency(code: "CNY")).font(.system(size: 10, weight: .bold)).monospacedDigit()
                        }
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Color.black.opacity(0.03)).clipShape(Capsule())
                        
                        Text("跟团到手价").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).padding(.top, 4)
                        
                        Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 68, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundStyle(LinearGradient(colors: [.primary, .primary.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
                            .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            ProfitCard(title: "优惠", value: result.maxPotentialDiscount, color: .primary)
                            Divider().frame(height: 24)
                            ProfitCard(title: "利润", value: result.actualProfit, color: result.actualProfit >= 0 ? .green : .red)
                            Divider().frame(height: 24)
                            ProfitPercentCard(title: "利润率", value: profitMargin, color: profitMargin >= 0 ? .blue : .red)
                        }
                        .padding(10).background(Color.white.opacity(0.4)).cornerRadius(12).padding(.bottom, 16)
                    }
                    Divider().overlay(Color.black.opacity(0.05))
                    ScrollView {
                        VStack(spacing: 16) {
                            GlassSection(title: "收入", icon: "arrow.down.forward.circle.fill", color: .green) {
                                DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                                DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                            }
                            GlassSection(title: "支出", icon: "arrow.up.forward.circle.fill", color: .red) {
                                if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "交易费", value: -v, color: .red) }
                                if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利费", value: -v, color: .red) }
                                if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金", value: -v, color: .red) }
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(width: 250)
            }
            .frame(width: 480)
            .liquidGlassStyle() // 应用玻璃外壳
            // 【核心修改】移除了外层的 padding(20)，让卡片直接贴合窗口边缘
            .ignoresSafeArea()
            
            // === 设置按钮 (悬浮) ===
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary.opacity(0.5)) // 稍微淡一点，不抢眼
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16) // 与左侧红绿灯对齐
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
                .frame(width: 400, height: 500)
        }
    }
}

// 组件定义 (保持不变)
struct InputCard: View { let title: String; @Binding var value: Double?; let color: Color; var body: some View { VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 2); TextField("0", value: $value, format: .number.grouping(.never)).font(.system(size: 28, weight: .semibold, design: .rounded)).foregroundStyle(color).textFieldStyle(.plain) }.padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.25)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1)) } }
struct GlassButton: View { let title: String; let isSelected: Bool; let color: Color; let action: () -> Void; var body: some View { Button(action: action) { Text(title).font(.system(size: 11, weight: isSelected ? .bold : .medium)).foregroundStyle(isSelected ? .white : .primary.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth: .infinity).padding(.vertical, 6).contentShape(Rectangle()) }.buttonStyle(.plain).background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? color.gradient : Color.white.opacity(0.2).gradient)).overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .white.opacity(0.6) : .white.opacity(0.4), lineWidth: 1)).scaleEffect(isSelected ? 1.02 : 1.0) } }
struct ProfitCard: View { let title: String; let value: Double; let color: Color; var body: some View { VStack(spacing: 1) { Text(title).font(.system(size: 9)).foregroundStyle(.secondary); Text(value, format: .number.precision(.fractionLength(1))).font(.system(size: 12, weight: .bold)).foregroundStyle(color) }.frame(maxWidth: .infinity) } }
struct ProfitPercentCard: View { let title: String; let value: Double; let color: Color; var body: some View { VStack(spacing: 1) { Text(title).font(.system(size: 9)).foregroundStyle(.secondary); Text(value, format: .percent.precision(.fractionLength(2))).font(.system(size: 12, weight: .bold)).foregroundStyle(color) }.frame(maxWidth: .infinity) } }
struct GlassSection<Content: View>: View { let title: String; let icon: String; let color: Color; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: icon).font(.system(size: 10)).foregroundStyle(color); Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary) }; VStack(spacing: 8) { content }.padding(10).background(Color.white.opacity(0.2)).cornerRadius(10) } } }
struct DetailRow: View { let label: String; let value: Double?; let color: Color; var body: some View { HStack { Text(label).font(.system(size: 11)).foregroundStyle(.secondary); Spacer(); if let v = value { Text(v, format: .currency(code: "CNY")).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(color) } } } }
EOF
