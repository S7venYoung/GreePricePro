import SwiftUI

struct CalculatorView: View {
    @ObservedObject var settings: AppSettings
    @State private var priceInput: Double = 3699
    @State private var selectedTier: ProductTier = .midRange
    @State private var selectedChannel: ChannelType = .normal
    
    var body: some View {
        HStack(spacing: 0) {
            Form {
                Section(header: Text("参数输入").font(.headline)) {
                    TextField("商品指导价", value: $priceInput, format: .currency(code: "CNY"))
                        .font(.title2)
                        .padding(.vertical, 5)
                    Picker("机型档位", selection: $selectedTier) {
                        ForEach(ProductTier.allCases) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    Picker("销售渠道", selection: $selectedChannel) {
                        ForEach(ChannelType.allCases) { channel in
                            Text(channel.rawValue).tag(channel)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                .padding()
            }
            .frame(minWidth: 300)
            
            Divider()
            
            VStack(spacing: 20) {
                let result = PriceCalculator.calculate(
                    price: priceInput,
                    tier: selectedTier,
                    channel: selectedChannel,
                    settings: settings
                )
                
                VStack(spacing: 10) {
                    Text("最大可优惠金额")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(result.maxDiscount, format: .currency(code: "CNY"))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.top, 40)
                
                Divider().padding(.horizontal)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("最低到手价")
                            .font(.caption)
                        Text(result.finalPrice, format: .currency(code: "CNY"))
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("综合净利点")
                            .font(.caption)
                        Text(result.netRate, format: .percent.precision(.fractionLength(2)))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
                
                List {
                    Section(header: Text("费用构成预估")) {
                        HStack { Text("总收入比率"); Spacer(); Text(result.totalIncomeRate, format: .percent.precision(.fractionLength(2))).foregroundColor(.green) }
                        HStack { Text("总扣除比率"); Spacer(); Text(result.totalDeductionRate, format: .percent.precision(.fractionLength(2))).foregroundColor(.red) }
                        ForEach(result.profitDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key).font(.caption)
                                Spacer()
                                Text(value, format: .currency(code: "CNY")).font(.caption)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                Spacer()
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}
