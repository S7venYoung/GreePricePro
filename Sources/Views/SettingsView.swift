import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("机型佣金点位 (小数)")) {
                TextField("低端挂机", value: $settings.rateLowWall, format: .number)
                TextField("低端柜机", value: $settings.rateLowCabinet, format: .number)
                TextField("普通机", value: $settings.rateOrdinary, format: .number)
                TextField("中端机", value: $settings.rateMidRange, format: .number)
                TextField("高端机", value: $settings.rateHighRange, format: .number)
            }
            Section(header: Text("京东平台收费")) {
                TextField("平台基础扣点", value: $settings.platformBaseDeduction, format: .number)
                TextField("交易服务费", value: $settings.transactionServiceFee, format: .number)
                TextField("返利框架费", value: $settings.rebateFrameworkFee, format: .number)
                TextField("降扣后扣点", value: $settings.reducedDeduction, format: .number)
            }
            Section(header: Text("收入项")) {
                TextField("补贴平台费", value: $settings.subsidyPlatformFee, format: .number)
            }
        }
        .padding()
        .frame(maxWidth: 500)
    }
}
