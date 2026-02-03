import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                platformRatesSection
                specialChannelSection
                subsidySection
                tierRatesSection
            }
            .formStyle(.grouped)
            .navigationTitle("参数配置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Subviews (拆分视图以通过编译)
    
    private var platformRatesSection: some View {
        Section("平台费率配置") {
            LabeledContent("平台基础扣点") {
                TextField("0.0", value: $settings.platformBaseDeduction, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("返利框架费") {
                TextField("0.0", value: $settings.rebateFrameworkFee, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("平台交易服务费") {
                TextField("0.0", value: $settings.transactionServiceFee, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var specialChannelSection: some View {
        Section("特殊渠道配置") {
            LabeledContent("降扣后费率 (直播/CPS)") {
                TextField("0.0", value: $settings.reducedDeduction, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("CPS外分佣金比例") {
                TextField("0.0", value: $settings.cpsBaseCommissionExternal, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var subsidySection: some View {
        Section("补贴相关") {
            LabeledContent("补贴平台费") {
                TextField("0.0", value: $settings.subsidyPlatformFee, format: .percent)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var tierRatesSection: some View {
        Section("机型佣金率 (自动保存)") {
            ForEach(ProductTier.allCases) { tier in
                TierRateRow(settings: settings, tier: tier)
            }
        }
    }
}

// 提取单独的行视图，进一步降低复杂度
struct TierRateRow: View {
    @ObservedObject var settings: AppSettings
    let tier: ProductTier
    
    var body: some View {
        HStack {
            Text(tier.rawValue)
            Spacer()
            // 使用计算属性构造 Binding
            TextField("0.0", value: binding, format: .percent)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var binding: Binding<Double> {
        Binding(
            get: { settings.getTierRate(tier) },
            set: { settings.setTierRate(tier, rate: $0) }
        )
    }
}
