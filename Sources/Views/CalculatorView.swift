import SwiftUI

// MARK: - 风格组件
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
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
    
    let gridColumns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
    
    var body: some View {
        // 【核心修改】直接作为根视图，不包 ZStack/Spacer，让窗口贴合这个尺寸
        HStack(spacing: 0) {
            // === 左侧 ===
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 8) {
                    InputCard(title: "官方指导价", value: $priceInput, color: .primary)
                    InputCard(title: "团购优惠", value: $groupDiscountInput, color: .indigo)
                }
                Divider().overlay(Color.black.opacity(0.05))
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("机型档次", systemImage: "air.conditioner.horizontal").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        LazyVGrid(columns: gridColumns, spacing: 6) {
                            ForEach(ProductTier.allCases) { tier in
                                GlassButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .blue) { withAnimation(.snappy) { selectedTier = tier } }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Label("销售渠道", systemImage: "network").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        LazyVGrid(columns: gridColumns, spacing: 6) {
                            ForEach(ChannelType.allCases) { channel in
                                GlassButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) { withAnimation(.snappy) { selectedChannel = channel } }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 220) 
            
            Rectangle().fill(LinearGradient(colors: [.clear, .black.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)).frame(width: 1).padding(.vertical, 16)
            
            // === 右侧 ===
            VStack(spacing: 0) {
                let result = PriceCalculator.calculate(originalPrice: priceInput ?? 0, groupDiscountInput: groupDiscountInput ?? 0, tier: selectedTier, channel: selectedChannel, settings: settings)
                let profitMargin = result.subsidyPrice > 0 ? result.actualProfit / result.subsidyPrice : 0
                
                VStack(spacing: 4) {
                    HStack {
                        Text("国补后基准").font(.system(size: 9)).foregroundStyle(.secondary)
                        Text(result.subsidyPrice, format: .currency(code: "CNY")).font(.system(size: 9, weight: .bold)).monospacedDigit()
                    }
                    .padding(.horizontal, 6).padding(.vertical, 2).background(Color.black.opacity(0.03)).clipShape(Capsule()).padding(.top, 16)
                    
                    Text("跟团到手价").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).padding(.top, 4)
                    
                    Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                        .foregroundStyle(LinearGradient(colors: [.primary, .primary.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
                        .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal)
                    
                    HStack(spacing: 0) {
                        ProfitCard(title: "优惠", value: result.maxPotentialDiscount, color: .primary)
                        Divider().frame(height: 20)
                        ProfitCard(title: "利润", value: result.actualProfit, color: result.actualProfit >= 0 ? .green : .red)
                        Divider().frame(height: 20)
                        ProfitPercentCard(title: "利润率", value: profitMargin, color: profitMargin >= 0 ? .blue : .red)
                    }
                    .padding(8).background(Color.white.opacity(0.4)).cornerRadius(10).padding(.bottom, 12)
                }
                Divider().overlay(Color.black.opacity(0.05))
                ScrollView {
                    VStack(spacing: 12) {
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
                    .padding(14)
                }
            }
            .frame(width: 240)
        }
        .frame(width: 460) // 固定内容宽度
        .liquidGlassStyle()
        .padding(20) // 给阴影留出呼吸空间
        .background(FluidBackground()) // 背景作为修饰，填充这个区域
    }
}

// 组件定义 (保持紧凑)
struct InputCard: View { let title: String; @Binding var value: Double?; let color: Color; var body: some View { VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 2); TextField("0", value: $value, format: .number.grouping(.never)).font(.system(size: 26, weight: .semibold, design: .rounded)).foregroundStyle(color).textFieldStyle(.plain) }.padding(8).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.25)).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1)) } }
struct GlassButton: View { let title: String; let isSelected: Bool; let color: Color; let action: () -> Void; var body: some View { Button(action: action) { Text(title).font(.system(size: 10, weight: isSelected ? .bold : .medium)).foregroundStyle(isSelected ? .white : .primary.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth: .infinity).padding(.vertical, 5).contentShape(Rectangle()) }.buttonStyle(.plain).background(RoundedRectangle(cornerRadius: 7).fill(isSelected ? color.gradient : Color.white.opacity(0.2).gradient)).overlay(RoundedRectangle(cornerRadius: 7).stroke(isSelected ? .white.opacity(0.6) : .white.opacity(0.4), lineWidth: 1)).scaleEffect(isSelected ? 1.02 : 1.0) } }
struct ProfitCard: View { let title: String; let value: Double; let color: Color; var body: some View { VStack(spacing: 1) { Text(title).font(.system(size: 8)).foregroundStyle(.secondary); Text(value, format: .number.precision(.fractionLength(1))).font(.system(size: 11, weight: .bold)).foregroundStyle(color) }.frame(maxWidth: .infinity) } }
struct ProfitPercentCard: View { let title: String; let value: Double; let color: Color; var body: some View { VStack(spacing: 1) { Text(title).font(.system(size: 8)).foregroundStyle(.secondary); Text(value, format: .percent.precision(.fractionLength(2))).font(.system(size: 11, weight: .bold)).foregroundStyle(color) }.frame(maxWidth: .infinity) } }
struct GlassSection<Content: View>: View { let title: String; let icon: String; let color: Color; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 6) { HStack { Image(systemName: icon).font(.system(size: 9)).foregroundStyle(color); Text(title).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary) }; VStack(spacing: 6) { content }.padding(8).background(Color.white.opacity(0.2)).cornerRadius(8) } } }
struct DetailRow: View { let label: String; let value: Double?; let color: Color; var body: some View { HStack { Text(label).font(.system(size: 10)).foregroundStyle(.secondary); Spacer(); if let v = value { Text(v, format: .currency(code: "CNY")).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(color) } } } }
struct FluidBackground: View { var body: some View { GeometryReader { proxy in ZStack { Color(nsColor: .windowBackgroundColor).opacity(0.5); Circle().fill(Color.blue.opacity(0.15)).frame(width: 400, height: 400).offset(x: -100, y: -100).blur(radius: 80); Circle().fill(Color.purple.opacity(0.15)).frame(width: 300, height: 300).offset(x: proxy.size.width - 100, y: proxy.size.height - 100).blur(radius: 60) } } } } // ignoresSafeArea 移除，跟随内容
