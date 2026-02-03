import Foundation

enum ProductTier: String, CaseIterable, Identifiable {
    case lowWall = "低端挂机"
    case lowCabinet = "低端柜机"
    case ordinary = "普通机"
    case midRange = "中端机"
    case highRange = "高端机"
    
    var id: String { self.rawValue }
}

enum ChannelType: String, CaseIterable, Identifiable {
    case normal = "非降扣渠道"
    case livestream = "直播间渠道"
    case cpsSelf = "CPS (佣金自拿)"
    case cpsExternal = "CPS (佣金外分)"
    
    var id: String { self.rawValue }
}

struct CalculationResult {
    let maxDiscount: Double
    let finalPrice: Double
    let totalIncomeRate: Double
    let totalDeductionRate: Double
    let netRate: Double
    let profitDetails: [String: Double]
}

class PriceCalculator {
    static func calculate(price: Double, tier: ProductTier, channel: ChannelType, settings: AppSettings) -> CalculationResult {
        let commissionRate = settings.getTierRate(tier)
        let subsidyFee = settings.subsidyPlatformFee
        let transactionFee = settings.transactionServiceFee
        
        let totalIncomeRate = commissionRate + subsidyFee
        
        var totalDeductionRate: Double = transactionFee
        var details: [String: Double] = [:]
        
        details["机型佣金"] = price * commissionRate
        details["平台补贴"] = price * subsidyFee
        
        switch channel {
        case .normal:
            let deduction = settings.platformBaseDeduction + settings.rebateFrameworkFee
            totalDeductionRate += deduction
        case .livestream, .cpsSelf:
            totalDeductionRate += settings.reducedDeduction
        case .cpsExternal:
            totalDeductionRate += settings.reducedDeduction + settings.cpsBaseCommissionExternal
        }
        
        let netRate = totalIncomeRate - totalDeductionRate
        let maxDiscount = price * netRate
        let finalPrice = price - maxDiscount
        
        return CalculationResult(
            maxDiscount: maxDiscount,
            finalPrice: finalPrice,
            totalIncomeRate: totalIncomeRate,
            totalDeductionRate: totalDeductionRate,
            netRate: netRate,
            profitDetails: details
        )
    }
}
