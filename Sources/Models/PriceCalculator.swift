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
    let subsidyPrice: Double      // 国补到手价 (新基数)
    let maxPotentialDiscount: Double // 理论最大可优惠金额 (基于费率)
    let groupPrice: Double        // 跟团到手价 (用户实际付的钱)
    let actualProfit: Double      // 实际利润 (理论最大优惠 - 实际团购优惠)
    let netRate: Double           // 净费率差
    let profitDetails: [String: Double] // 详细账单
}

class PriceCalculator {
    
    // 计算国补到手价
    static func calculateSubsidyPrice(originalPrice: Double) -> Double {
        // 规则：优惠 15%，最高 2000
        let discount = originalPrice * 0.15
        let actualDiscount = min(discount, 2000)
        return originalPrice - actualDiscount
    }

    static func calculate(originalPrice: Double, groupDiscountInput: Double, tier: ProductTier, channel: ChannelType, settings: AppSettings) -> CalculationResult {
        
        // 1. 先算国补到手价 (所有后续计算的基数)
        let basePrice = calculateSubsidyPrice(originalPrice: originalPrice)
        
        // 2. 获取费率配置
        let commissionRate = settings.getTierRate(tier)
        let subsidyFee = settings.subsidyPlatformFee
        let transactionFee = settings.transactionServiceFee
        
        var details: [String: Double] = [:]
        
        // ============ 收入计算 (基于国补价) ============
        let incomeCommission = basePrice * commissionRate
        details["机型佣金"] = incomeCommission
        
        let incomeSubsidy = basePrice * subsidyFee
        details["补贴平台费"] = incomeSubsidy
        
        let totalIncomeRate = commissionRate + subsidyFee
        
        // ============ 支出计算 (基于国补价) ============
        var totalDeductionRate: Double = 0.0
        
        // 基础交易费
        let costTransaction = basePrice * transactionFee
        details["平台交易服务费"] = costTransaction
        totalDeductionRate += transactionFee
        
        // 渠道扣点
        switch channel {
        case .normal:
            let costBase = basePrice * settings.platformBaseDeduction
            details["平台基础扣点"] = costBase
            totalDeductionRate += settings.platformBaseDeduction
            
            let costRebate = basePrice * settings.rebateFrameworkFee
            details["返利框架费"] = costRebate
            totalDeductionRate += settings.rebateFrameworkFee
            
        case .livestream, .cpsSelf:
            let costReduced = basePrice * settings.reducedDeduction
            details["降扣后平台扣点"] = costReduced
            totalDeductionRate += settings.reducedDeduction
            
        case .cpsExternal:
            let costReduced = basePrice * settings.reducedDeduction
            details["降扣后平台扣点"] = costReduced
            totalDeductionRate += settings.reducedDeduction
            
            let costCPSExternal = basePrice * settings.cpsBaseCommissionExternal
            details["CPS佣金支出"] = costCPSExternal
            totalDeductionRate += settings.cpsBaseCommissionExternal
        }
        
        // ============ 结果推导 ============
        
        // 3. 净费率差 (收入率 - 支出率)
        let netRate = totalIncomeRate - totalDeductionRate
        
        // 4. 理论最大可优惠金额 (即：如果不留利润，最多能让利多少)
        // 公式：国补价 * 净费率
        let maxPotentialDiscount = basePrice * netRate
        
        // 5. 跟团到手价 (国补价 - 手动输入的团购优惠)
        let groupPrice = basePrice - groupDiscountInput
        
        // 6. 实际跟团利润 (理论最大优惠 - 实际给出的优惠)
        // 如果给出的优惠小于理论最大值，剩下的就是利润
        let actualProfit = maxPotentialDiscount - groupDiscountInput
        
        return CalculationResult(
            subsidyPrice: basePrice,
            maxPotentialDiscount: maxPotentialDiscount,
            groupPrice: groupPrice,
            actualProfit: actualProfit,
            netRate: netRate,
            profitDetails: details
        )
    }
}
