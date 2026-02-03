import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    @State private var priceInput: Double = 3699
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - 左侧控制台
                VStack(alignment: .leading, spacing: 24) {
                    // 价格输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("商品指导价 (¥)").font(.caption).foregroundColor(.secondary)
                        TextField("0", value: $priceInput, format: .number.grouping(.never))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                            .padding(.vertical, 4)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)).shadow(color: .black.opacity(0.05), radius: 2, y: 1))
                    
                    // 档位选择
                    VStack(alignment: .leading, spacing: 10) {
                        Label("机型档次", systemImage: "air.conditioner.horizontal").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(ProductTier.allCases) { tier in
                                SelectableButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .blue) { withAnimation(.snappy) { selectedTier = tier } }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 渠道选择
                    VStack(alignment: .leading, spacing: 10) {
                        Label("销售渠道", systemImage: "network").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                            ForEach(ChannelType.allCases) { channel in
                                SelectableButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) { withAnimation(.snappy) { selectedChannel = channel } }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(24)
                
                // MARK: - 右侧账单详情
                VStack(spacing: 0) {
                    let result = PriceCalculator.calculate(price: priceInput, tier: selectedTier, channel: selectedChannel, settings: settings)
                    
                    // 顶部结果
                    VStack(spacing: 4) {
                        Text("最低到手价").font(.subheadline).opacity(0.8)
                        Text(result.finalPrice, format: .currency(code: "CNY"))
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                        
                        HStack {
                            Text("优惠 ¥\(result.maxDiscount, specifier: "%.2f")")
                            Text("•")
                            Text("净利 \(result.netRate * 100, specifier: "%.2f")%")
                        }
                        .font(.caption).fontWeight(.bold)
                        .padding(6)
                        .background(Capsule().fill(profitColor(rate: result.netRate).opacity(0.15)))
                        .foregroundColor(profitColor(rate: result.netRate))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    Divider()
                    
                    // 详细列表
                    ScrollView {
                        VStack(spacing: 20) {
                            // 收入组
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "各项收入", icon: "arrow.down.circle.fill", color: .green)
                                Group {
                                    DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                                    DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                                }
                                .padding(.leading, 24)
                            }
                            
                            Divider().opacity(0.5)
                            
                            // 支出组
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "成本扣除", icon: "arrow.up.circle.fill", color: .red)
                                Group {
                                    // 动态显示存在的支出项
                                    if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "平台交易费", value: -v, color: .red) }
                                    if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                                    if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利框架费", value: -v, color: .red) }
                                    if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣后扣点", value: -v, color: .red) }
                                    if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金(外)", value: -v, color: .red) }
                                }
                                .padding(.leading, 24)
                            }
                        }
                        .padding()
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                }
                .frame(width: 340)
                .background(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 5, x: -1)
            }
        }
    }
    
    func profitColor(rate: Double) -> Color {
        if rate > 0.03 { return .green }
        if rate > 0.015 { return .orange }
        return .red
    }
}

// 辅助组件
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.subheadline).bold().foregroundColor(.secondary)
        }
    }
}

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
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? color.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: 1.5))
        )
        .foregroundColor(isSelected ? color : .primary)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

struct DetailRow: View {
    let label: String
    let value: Double?
    let color: Color
    
    var body: some View {
        HStack {
            Text(label).font(.callout).foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text(v, format: .currency(code: "CNY"))
                    .font(.body.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}
