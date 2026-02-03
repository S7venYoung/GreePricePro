非常抱歉，我之前保留了 maxWidth: .infinity，导致在大窗口下右侧面板会自动填充所有剩余空间，看起来确实太宽了。

这一次，我们将采取**“固定尺寸卡片”**的策略：

锁定宽度：左侧固定 240，右侧固定 260（稍微宽一点点以容纳大字体，但视觉上几乎一样宽）。

居中悬浮：整个计算器面板将固定在屏幕中央，不再随窗口拉伸而变形。即使你把窗口拉得再大，计算器本身也保持精致紧凑，就像桌面上的一个实体小摆件。

请运行下面的脚本更新 CalculatorView.swift：

Bash
cat <<'EOF' > Sources/Views/CalculatorView.swift
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
    
    @State private var priceInput: Double? = nil
    @State private var groupDiscountInput: Double? = nil
    
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    let gridColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        ZStack {
            // 1. 底层流体背景
            FluidBackground()
            
            // 2. 主体内容 (整体居中)
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    
                    // MARK: - 左侧控制台 (固定宽 240)
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. 价格输入
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
                    .frame(width: 240) // 【固定宽度】左侧
                    
                    // 中间分割线
                    Divider().overlay(Color.white.opacity(0.3))
                    
                    // MARK: - 右侧结果 (固定宽 260)
                    VStack(spacing: 0) {
                        let result = PriceCalculator.calculate(
                            originalPrice: priceInput ?? 0,
                            groupDiscountInput: groupDiscountInput ?? 0,
                            tier: selectedTier,
                            channel: selectedChannel,
                            settings: settings
                        )
                        
                        // 顶部结果展示
                        VStack(spacing: 8) {
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
                            
                            // 超大数字 (缩放适配)
                            Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                                .font(.system(size: 80, weight: .heavy, design: .rounded))
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
                                .minimumScaleFactor(0.4) // 允许缩放以适应较窄的宽度
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
                    .frame(width: 260) // 【固定宽度】右侧
                    .background(.ultraThinMaterial.opacity(0.5))
                }
                .fixedSize(horizontal: true, vertical: false) // 防止被 Spacer 挤压
                .cornerRadius(24) // 整体圆角
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10) // 整体阴影
                
                Spacer()
            }
        }
    }
}

// MARK: - 组件 (保持不变)

struct InputCard: View {
    let title: String; @Binding var value: Double?; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary).padding(.leading, 2)
            TextField("0", value: $value, format: .number.grouping(.never))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(color).textFieldStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.3)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

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
