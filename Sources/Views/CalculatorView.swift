import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    @State private var priceInput: Double = 3699
    @State private var groupDiscountInput: Double = 100
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    // 紧凑的双列网格
    let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - 左侧控制台 (Input)
            VStack(alignment: .leading, spacing: 16) {
                
                // 1. 价格输入
                VStack(alignment: .leading, spacing: 10) {
                    InputGroup(title: "官方指导价", value: $priceInput, color: .primary)
                    InputGroup(title: "团购优惠", value: $groupDiscountInput, color: .blue)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                Divider()
                
                // 2. 机型档次
                VStack(alignment: .leading, spacing: 8) {
                    Label("机型档次", systemImage: "air.conditioner.horizontal")
                        .font(.headline)
                    
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(ProductTier.allCases) { tier in
                            SelectableButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .gray) {
                                withAnimation(.snappy) { selectedTier = tier }
                            }
                        }
                    }
                }
                
                // 3. 销售渠道
                VStack(alignment: .leading, spacing: 8) {
                    Label("销售渠道", systemImage: "network")
                        .font(.headline)
                    
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(ChannelType.allCases) { channel in
                            SelectableButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) {
                                withAnimation(.snappy) { selectedChannel = channel }
                            }
                        }
                    }
                }
                
                Spacer() // 把内容顶上去
            }
            .padding(16)
            .frame(width: 280) // 【关键修改】固定左侧宽度，不再无限拉伸
            
            // 中间留白 (窗口拉大时，空白在这里)
            Spacer()
            
            // MARK: - 右侧结果 (Output)
            VStack(spacing: 0) {
                let result = PriceCalculator.calculate(
                    originalPrice: priceInput,
                    groupDiscountInput: groupDiscountInput,
                    tier: selectedTier,
                    channel: selectedChannel,
                    settings: settings
                )
                
                // 顶部结果
                VStack(spacing: 4) {
                    HStack {
                        Text("国补后基准: \(result.subsidyPrice, format: .currency(code: "CNY"))")
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Text("跟团到手价").font(.subheadline).foregroundColor(.secondary)
                    
                    Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    // 利润指示器
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text("最大优惠").font(.system(size: 9)).opacity(0.6)
                            Text(result.maxPotentialDiscount, format: .number.precision(.fractionLength(1))).font(.caption).bold()
                        }
                        Divider().frame(height: 16)
                        VStack(spacing: 1) {
                            Text("实际利润").font(.system(size: 9)).opacity(0.6)
                            Text(result.actualProfit, format: .number.precision(.fractionLength(1)))
                                .font(.callout).bold()
                                .foregroundColor(result.actualProfit >= 0 ? .green : .red)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor)).shadow(radius: 1))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // 详情列表
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader(title: "收入", icon: "arrow.down.circle.fill", color: .green)
                            DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                            DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                        }
                        Divider().opacity(0.3)
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader(title: "支出", icon: "arrow.up.circle.fill", color: .red)
                            if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "交易费", value: -v, color: .red) }
                            if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                            if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利费", value: -v, color: .red) }
                            if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣扣点", value: -v, color: .red) }
                            if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金", value: -v, color: .red) }
                        }
                    }
                    .padding(20)
                }
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(width: 300) // 右侧也稍微定宽一点，保持紧凑
            .shadow(color: .black.opacity(0.05), radius: 5, x: -1)
        }
    }
}

// MARK: - 精致化组件

struct InputGroup: View {
    let title: String
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            TextField("0", value: $value, format: .number.grouping(.never))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .textFieldStyle(.plain)
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
                .font(.system(size: 12)) // 字体变小
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6) // 高度变矮
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: 1))
        )
        .foregroundColor(isSelected ? color : .primary)
    }
}

// 保持不变的辅助组件
struct SectionHeader: View {
    let title: String; let icon: String; let color: Color
    var body: some View { HStack { Image(systemName: icon).foregroundColor(color); Text(title).font(.caption2).bold().foregroundColor(.secondary) } }
}

struct DetailRow: View {
    let label: String; let value: Double?; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            if let v = value { Text(v, format: .currency(code: "CNY")).font(.caption.monospacedDigit()).foregroundColor(color) }
        }
    }
}
