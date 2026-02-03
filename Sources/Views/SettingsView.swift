import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section("补贴相关") {
                    LabeledContent("补贴平台费") {
                        TextField("0.0", value: $settings.subsidyPlatformFee, format: .percent)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("机型佣金率 (自动保存)") {
                    ForEach(ProductTier.allCases) { tier in
                        HStack {
                            Text(tier.rawValue)
                            Spacer()
                            TextField("0.0", value: Binding(
                                get: { settings.getTierRate(tier) },
                                set: { settings.setTierRate(tier, rate: $0) }
                            ), format: .percent)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
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
}
