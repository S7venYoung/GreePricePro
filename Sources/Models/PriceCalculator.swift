import Foundation

// 定义机型档次
enum ProductTier: String, CaseIterable, Identifiable {
    case lowWall = "低端挂机"
    case lowCabinet = "低端柜机"
    case ordinary = "普通机"
    case midRange = "中端机"
    case highRange = "高端机"
    
    var id: String { self.rawValue }
}

// 定义渠道类型
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
    let profitDetails: [String: Double] // 存储每一项的具体金额
}

class PriceCalculator {
    static func calculate(price: Double, tier: ProductTier, channel: ChannelType, settings: AppSettings) -> CalculationResult {
        
        // 1. 获取配置
        let commissionRate = settings.getTierRate(tier)
        let subsidyFee = settings.subsidyPlatformFee
        let transactionFee = settings.transactionServiceFee
        
        var details: [String: Double] = [:]
        
        // ============ 收入计算 ============
        // 机型佣金
        let incomeCommission = price * commissionRate
        details["机型佣金"] = incomeCommission
        
        // 补贴平台费
        let incomeSubsidy = price * subsidyFee
        details["补贴平台费"] = incomeSubsidy
        
        let totalIncomeRate = commissionRate + subsidyFee
        
        // ============ 支出计算 ============
        var totalDeductionRate: Double = 0.0
        
        // 1. 基础交易费 (每单必扣)
        let costTransaction = price * transactionFee
        details["平台交易服务费"] = costTransaction
        totalDeductionRate += transactionFee
        
        // 2. 渠道相关扣点
        switch channel {
        case .normal:
            // 非降扣渠道：基础扣点 + 返利框架费
            let costBase = price * settings.platformBaseDeduction
            details["平台基础扣点"] = costBase
            totalDeductionRate += settings.platformBaseDeduction
            
            let costRebate = price * settings.rebateFrameworkFee
            details["返利框架费"] = costRebate
            totalDeductionRate += settings.rebateFrameworkFee
            
        case .livestream, .cpsSelf:
            // 直播或CPS自拿：只扣降扣后的点
            let costReduced = price * settings.reducedDeduction
            details["降扣后平台扣点"] = costReduced
            totalDeductionRate += settings.reducedDeduction
            
        case .cpsExternal:
            // CPS外分：降扣点 + 给别人的佣金
            let costReduced = price * settings.reducedDeduction
            details["降扣后平台扣点"] = costReduced
            totalDeductionRate += settings.reducedDeduction
            
            let costCPSExternal = price * settings.cpsBaseCommissionExternal
            details["CPS佣金支出"] = costCPSExternal
            totalDeductionRate += settings.cpsBaseCommissionExternal
        }
        
        // ============ 结果汇总 ============
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
