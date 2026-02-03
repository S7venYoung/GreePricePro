import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    
    @State private var priceInput: Double = 3699
    @State private var groupDiscountInput: Double = 100
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    // 双列网格 (自适应)
    let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        // 使用 spacing: 0 紧凑排列，中间用 Divider 分隔
        HStack(spacing: 0) {
            
            // MARK: - 左侧控制台 (弹性)
            VStack(alignment: .leading, spacing: 20) {
                // 1. 价格输入
                VStack(alignment: .leading, spacing: 12) {
                    InputGroup(title: "官方指导价", value: $priceInput, color: .primary)
                    InputGroup(title: "团购优惠", value: $groupDiscountInput, color: .blue)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // 2. 机型档次
                VStack(alignment: .leading, spacing: 10) {
                    Label("机型档次", systemImage: "air.conditioner.horizontal")
                        .font(.headline)
                    
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(ProductTier.allCases) { tier in
                            SelectableButton(title: tier.rawValue, isSelected: selectedTier == tier, color: .gray) {
                                withAnimation(.snappy) { selectedTier = tier }
                            }
                        }
                    }
                }
                
                // 3. 销售渠道
                VStack(alignment: .leading, spacing: 10) {
                    Label("销售渠道", systemImage: "network")
                        .font(.headline)
                    
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
            .frame(minWidth: 280, maxWidth: .infinity) // 【修改】允许拉伸
            
            // 中间分割线
            Divider()
            
            // MARK: - 右侧结果 (弹性)
            VStack(spacing: 0) {
                let result = PriceCalculator.calculate(
                    originalPrice: priceInput,
                    groupDiscountInput: groupDiscountInput,
                    tier: selectedTier,
                    channel: selectedChannel,
                    settings: settings
                )
                
                // 顶部结果区域
                VStack(spacing: 6) {
                    HStack {
                        Text("国补后基准: \(result.subsidyPrice, format: .currency(code: "CNY"))")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    .padding(.top, 10)
                    
                    Text("跟团到手价")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    // 大数字，允许缩放
                    Text(result.groupPrice, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.vertical, 4)
                    
                    // 利润指示器
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("最大优惠").font(.caption).opacity(0.6)
                            Text(result.maxPotentialDiscount, format: .number.precision(.fractionLength(1)))
                                .font(.headline)
                        }
                        Divider().frame(height: 24)
                        VStack(spacing: 4) {
                            Text("实际利润").font(.caption).opacity(0.6)
                            Text(result.actualProfit, format: .number.precision(.fractionLength(1)))
                                .font(.title3).bold()
                                .foregroundColor(result.actualProfit >= 0 ? .green : .red)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .windowBackgroundColor)).shadow(radius: 1))
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity) // 填满宽度
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // 详情列表
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "各项收入", icon: "arrow.down.circle.fill", color: .green)
                            DetailRow(label: "机型佣金", value: result.profitDetails["机型佣金"], color: .green)
                            DetailRow(label: "补贴平台费", value: result.profitDetails["补贴平台费"], color: .green)
                        }
                        
                        Divider().opacity(0.3)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "成本扣除", icon: "arrow.up.circle.fill", color: .red)
                            if let v = result.profitDetails["平台交易服务费"] { DetailRow(label: "交易费", value: -v, color: .red) }
                            if let v = result.profitDetails["平台基础扣点"] { DetailRow(label: "基础扣点", value: -v, color: .red) }
                            if let v = result.profitDetails["返利框架费"] { DetailRow(label: "返利费", value: -v, color: .red) }
                            if let v = result.profitDetails["降扣后平台扣点"] { DetailRow(label: "降扣扣点", value: -v, color: .red) }
                            if let v = result.profitDetails["CPS佣金支出"] { DetailRow(label: "CPS佣金", value: -v, color: .red) }
                        }
                    }
                    .padding(30)
                }
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(minWidth: 320, maxWidth: .infinity) // 【修改】允许拉伸
        }
    }
}

// MARK: - 组件

struct DetailRow: View {
    let label: String
    let value: Double?
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text(v, format: .currency(code: "CNY"))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.secondary)
        }
    }
}

struct InputGroup: View {
    let title: String; @Binding var value: Double; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField("0", value: $value, format: .number.grouping(.never))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(color).textFieldStyle(.plain)
        }
    }
}

struct SelectableButton: View {
    let title: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 13)).lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity).padding(.vertical, 8).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: 1)))
        .foregroundColor(isSelected ? color : .primary)
    }
}
