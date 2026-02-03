import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    // 输入状态
    @State private var priceInput: Double = 3699
    @State private var groupDiscountInput: Double = 100
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    // 定义双列网格布局 (固定两列，自动伸缩)
    let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - 左侧控制台
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 1. 价格输入组
                    VStack(alignment: .leading, spacing: 12) {
                        // 指导价
                        VStack(alignment: .leading, spacing: 4) {
                            Text("官方指导价 (¥)").font(.caption).foregroundColor(.secondary)
                            TextField("0", value: $priceInput, format: .number.grouping(.never))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .textFieldStyle(.plain)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                        
                        // 团购优惠
                        VStack(alignment: .leading, spacing: 4) {
                            Text("团购优惠金额 (¥)").font(.caption).foregroundColor(.blue)
                            TextField("0", value: $groupDiscountInput, format: .number.grouping(.never))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                                .textFieldStyle(.plain)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.1)))
                    }
                    
                    Divider()
                    
                    // 2. 机型档次 (双列布局)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("机型档次", systemImage: "air.conditioner.horizontal")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(ProductTier.allCases) { tier in
                                SelectableButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .gray) {
                                    withAnimation(.snappy) { selectedTier = tier }
                                }
                            }
                        }
                    }
                    
                    // 3. 销售渠道 (双列布局)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("销售渠道", systemImage: "network")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(ChannelType.allCases) { channel in
                                SelectableButton(title: channel.rawValue, isSelected: selectedChannel == channel, color: .orange) {
                                    withAnimation(.snappy) { selectedChannel = channel }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                
                // MARK: - 右侧结果面板
                VStack(spacing: 0) {
                    let result = PriceCalculator.calculate(
                        originalPrice: priceInput,
                        groupDiscountInput: groupDiscountInput,
                        tier: selectedTier,
                        channel: selectedChannel,
                        settings: settings
                    )
                    
                    // 顶部核心结果
                    VStack(spacing: 6) {
                        // 国补价提示
                        HStack {
                            Text("国补后基准: \(result.subsidyPrice, format: .currency(code: "CNY"))")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        }
                        
                        Text("跟团到手价")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 纯数字显示 (无货币符号)
                        Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 60, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundColor(.primary)
                        
                        // 利润提示卡片
                        HStack(spacing: 12) {
                            VStack(spacing: 2) {
                                Text("理论最大优惠")
                                    .font(.system(size: 10))
                                    .opacity(0.7)
                                Text(result.maxPotentialDiscount, format: .number.precision(.fractionLength(1)))
                                    .font(.callout).bold()
                            }
                            
                            Divider().frame(height: 20)
                            
                            VStack(spacing: 2) {
                                Text("本单实际利润")
                                    .font(.system(size: 10))
                                    .opacity(0.7)
                                Text(result.actualProfit, format: .number.precision(.fractionLength(1)))
                                    .font(.title3).bold()
                                    .foregroundColor(result.actualProfit >= 0 ? .green : .red)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .windowBackgroundColor)).shadow(radius: 1))
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    Divider()
                    
                    // 底部详情列表
                    ScrollView {
                        VStack(spacing: 16) {
                            // 收入详情
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "收入构成 (基于国补价)", icon: "arrow.down.circle.fill", color: .green)
                                DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                                DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                            }
                            
                            Divider().opacity(0.5)
                            
                            // 支出详情
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "成本扣除 (基于国补价)", icon: "arrow.up.circle.fill", color: .red)
                                if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "平台交易费", value: -v, color: .red) }
                                if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利框架费", value: -v, color: .red) }
                                if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣后扣点", value: -v, color: .red) }
                                if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金", value: -v, color: .red) }
                            }
                        }
                        .padding(20)
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                }
                .frame(width: 320)
                .background(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 5, x: -1)
            }
        }
    }
}

// UI 组件 (保持不变)
struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10) // 稍微增加高度以适应两列
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: 1))
        )
        .foregroundColor(isSelected ? color : .primary)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.caption).bold().foregroundColor(.secondary)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: Double?
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text(v, format: .currency(code: "CNY"))
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}
