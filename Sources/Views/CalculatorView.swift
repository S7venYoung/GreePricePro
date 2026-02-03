import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    // 输入状态
    @State private var priceInput: Double = 3699
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    // 动画命名空间
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 20) {
                // MARK: - 左侧：控制台 (Input Deck)
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. 价格输入区 (像计算器的显示屏)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("商品指导价 (¥)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        TextField("0", value: $priceInput, format: .number.grouping(.never))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    
                    // 2. 机型档位选择 (网格按钮)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("机型档次", systemImage: "air.conditioner.horizontal")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(ProductTier.allCases) { tier in
                                SelectableButton(
                                    title: tier.rawValue,
                                    isSelected: selectedTier == tier,
                                    color: .blue
                                ) {
                                    withAnimation(.snappy) { selectedTier = tier }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 3. 销售渠道选择 (网格按钮)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("销售渠道", systemImage: "network")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                            ForEach(ChannelType.allCases) { channel in
                                SelectableButton(
                                    title: channel.rawValue,
                                    isSelected: selectedChannel == channel,
                                    color: .orange
                                ) {
                                    withAnimation(.snappy) { selectedChannel = channel }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                
                // MARK: - 右侧：账单/结果屏 (Receipt/Display)
                VStack(spacing: 0) {
                    let result = PriceCalculator.calculate(
                        price: priceInput,
                        tier: selectedTier,
                        channel: selectedChannel,
                        settings: settings
                    )
                    
                    // 顶部：最终价格大卡片
                    VStack(spacing: 5) {
                        Text("最低到手价")
                            .font(.title3)
                            .fontWeight(.medium)
                            .opacity(0.8)
                        
                        Text(result.finalPrice, format: .currency(code: "CNY"))
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText()) // 数字滚动动画
                            .foregroundColor(.primary)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                        
                        // 利润标签
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("净利点 \(result.netRate * 100, specifier: "%.2f")%")
                        }
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(profitColor(rate: result.netRate).opacity(0.2))
                        )
                        .foregroundColor(profitColor(rate: result.netRate))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    
                    Divider()
                    
                    // 中部：优惠详情 (优惠券风格)
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("最大优惠力度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(result.maxDiscount, format: .currency(code: "CNY"))
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("机型佣金")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("+\(result.profitDetails["机型佣金"] ?? 0, format: .currency(code: "CNY"))")
                                    .font(.body)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .shadow(radius: 1)
                        )
                        
                        // 底部：详细列表
                        ScrollView {
                            VStack(spacing: 12) {
                                DetailRow(label: "平台补贴", value: result.profitDetails["平台补贴"], color: .green)
                                Divider()
                                DetailRow(label: "总扣点支出", value: -(priceInput * result.totalDeductionRate), color: .red)
                            }
                            .padding()
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor))
                }
                .frame(width: 320) // 固定右侧宽度
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .shadow(radius: 10)
            }
        }
    }
    
    // 利润颜色助手
    func profitColor(rate: Double) -> Color {
        if rate > 0.03 { return .green }
        if rate > 0.015 { return .orange }
        return .red
    }
}

// MARK: - UI Components

struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .foregroundColor(isSelected ? color : .primary)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct DetailRow: View {
    let label: String
    let value: Double?
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text(v, format: .currency(code: "CNY"))
                    .font(.body.monospacedDigit())
                    .foregroundColor(color)
            } else {
                Text("--")
            }
        }
    }
}
