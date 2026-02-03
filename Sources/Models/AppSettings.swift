import Foundation
import Combine

class AppSettings: ObservableObject {
    // 平台费率
    @Published var platformBaseDeduction: Double = 0.08
    @Published var rebateFrameworkFee: Double = 0.02
    @Published var transactionServiceFee: Double = 0.006
    
    // 特殊渠道
    @Published var reducedDeduction: Double = 0.02
    @Published var cpsBaseCommissionExternal: Double = 0.05
    
    // 补贴
    @Published var subsidyPlatformFee: Double = 0.035
    
    // 机型佣金 (默认值)
    @Published var tierRates: [ProductTier: Double] = [
        .lowWall: 0.04,
        .lowCabinet: 0.05,
        .ordinary: 0.06,
        .midRange: 0.08,
        .highRange: 0.12
    ]
    
    // Helper methods (Optional, but good for compatibility)
    func getTierRate(_ tier: ProductTier) -> Double {
        return tierRates[tier] ?? 0.0
    }
    
    func setTierRate(_ tier: ProductTier, rate: Double) {
        tierRates[tier] = rate
    }
}
