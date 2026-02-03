import SwiftUI

// MARK: - Liquid Glass 风格修饰符
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func liquidGlassStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius))
    }
}

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    // 【修改】改为可选值 (Optional)，默认为 nil，即留空
    @State private var priceInput: Double? = nil
    @State private var groupDiscountInput: Double? = nil
    
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    // 双列网格
    let gridColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        ZStack {
            // 1. 底层流体背景
            FluidBackground()
            
            // 2. 主体内容
            HStack(spacing: 0) {
                
                // MARK: - 左侧控制台
                VStack(alignment: .leading, spacing: 18) {
                    
                    // 1. 价格输入区
                    VStack(spacing: 12) {
                        InputCard(title: "官方指导价", value: $priceInput, color: .primary)
                        InputCard(title: "团购优惠", value: $groupDiscountInput, color: .indigo)
                    }
                    
                    // 2. 选项区
                    VStack(alignment: .leading, spacing: 18) {
                        // 机型档次
                        VStack(alignment: .leading, spacing: 8) {
                            Label("机型档次", systemImage: "air.conditioner.horizontal")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(ProductTier.allCases) { tier in
                                    GlassButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .blue) {
                                        withAnimation(.snappy) { selectedTier = tier }
                                    }
                                }
                            }
                        }
                        
                        // 销售渠道
                        VStack(alignment: .leading, spacing: 8) {
                            Label("销售渠道", systemImage: "network")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(ChannelType.allCases) { channel in
                                    GlassButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) {
                                        withAnimation(.snappy) { selectedChannel = channel }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                .frame(width: 240) // 左侧固定 240
                
                // 中间分割线
                Divider().overlay(Color.white.opacity(0.3))
                
                // MARK: - 右侧结果
                VStack(spacing: 0) {
                    // 计算逻辑：如果输入为空，则视为 0 进行计算
                    let result = PriceCalculator.calculate(
                        originalPrice: priceInput ?? 0,
                        groupDiscountInput: groupDiscountInput ?? 0,
                        tier: selectedTier,
                        channel: selectedChannel,
                        settings: settings
                    )
                    
                    // 顶部结果展示
                    VStack(spacing: 8) {
                        // 国补胶囊
                        HStack {
                            Text("国补后基准")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(result.subsidyPrice, format: .currency(code: "CNY"))
                                .font(.caption).bold().monospacedDigit()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5))
                        .padding(.top, 24)
                        
                        Text("跟团到手价")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        // 超大数字
                        Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 84, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .padding(.horizontal)
                        
                        // 利润仪表盘
                        HStack(spacing: 0) {
                            ProfitCard(title: "最大优惠", value: result.maxPotentialDiscount, color: .primary)
                            Divider().frame(height: 30)
                            ProfitCard(title: "实际利润", value: result.actualProfit, color: result.actualProfit >= 0 ? .green : .red)
                        }
                        .padding(12)
                        .background(.white.opacity(0.4))
                        .cornerRadius(16)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().overlay(Color.black.opacity(0.05))
                    
                    // 详情列表
                    ScrollView {
                        VStack(spacing: 24) {
                            GlassSection(title: "收入构成", icon: "arrow.down.forward.circle.fill", color: .green) {
                                DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                                DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                            }
                            
                            GlassSection(title: "成本扣除", icon: "arrow.up.forward.circle.fill", color: .red) {
                                if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "交易费", value: -v, color: .red) }
                                if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利费", value: -v, color: .red) }
                                if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金", value: -v, color: .red) }
                            }
                        }
                        .padding(24)
                    }
                }
                .frame(minWidth: 240, maxWidth: .infinity) // 【修改】最小宽度设为 240 (与左侧一致)
                .background(.ultraThinMaterial.opacity(0.5))
            }
        }
    }
}

// MARK: - 组件升级

// 独立的输入卡片 (支持可选值)
struct InputCard: View {
    let title: String
    @Binding var value: Double? // 【修改】绑定可选类型
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary).padding(.leading, 2)
            
            // 使用 TextField 绑定可选值，placeholder 设为 0
            TextField("0", value: $value, format: .number.grouping(.never))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(color).textFieldStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.3))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

// 玻璃按钮 (保持不变)
struct GlassButton: View {
    let title: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.8))
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity).padding(.vertical, 8).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? color.gradient : Color.white.opacity(0.15).gradient).shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 5, y: 2))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .white.opacity(0.6) : .white.opacity(0.5), lineWidth: isSelected ? 1 : 1.5))
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// 流体背景 (保持不变)
struct FluidBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(nsColor: .windowBackgroundColor).opacity(0.5)
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 400, height: 400).offset(x: -100, y: -100).blur(radius: 80)
                Circle().fill(Color.purple.opacity(0.15)).frame(width: 300, height: 300).offset(x: proxy.size.width - 100, y: proxy.size.height - 100).blur(radius: 60)
                Circle().fill(Color.orange.opacity(0.1)).frame(width: 200, height: 200).offset(x: 100, y: proxy.size.height / 2).blur(radius: 50)
            }
        }
        .ignoresSafeArea()
    }
}

// 利润卡片 (保持不变)
struct ProfitCard: View {
    let title: String; let value: Double; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value, format: .number.precision(.fractionLength(1))).font(.headline).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// 玻璃分区 (保持不变)
struct GlassSection<Content: View>: View {
    let title: String; let icon: String; let color: Color; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: icon).foregroundStyle(color); Text(title).font(.subheadline).bold().foregroundStyle(.secondary) }
            VStack(spacing: 12) { content }
            .padding(16).background(Color.white.opacity(0.2)).cornerRadius(12)
        }
    }
}

// 详情行 (保持不变)
struct DetailRow: View {
    let label: String; let value: Double?; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            if let v = value { Text(v, format: .currency(code: "CNY")).font(.callout.monospacedDigit()).fontWeight(.medium).foregroundStyle(color) }
        }
    }
}
