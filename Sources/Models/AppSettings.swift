import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("rate_lowWall") var rateLowWall: Double = 0.02
    @AppStorage("rate_lowCabinet") var rateLowCabinet: Double = 0.03
    @AppStorage("rate_ordinary") var rateOrdinary: Double = 0.03
    @AppStorage("rate_midRange") var rateMidRange: Double = 0.04
    @AppStorage("rate_highRange") var rateHighRange: Double = 0.06
    
    @AppStorage("subsidyPlatformFee") var subsidyPlatformFee: Double = 0.053
    @AppStorage("transactionServiceFee") var transactionServiceFee: Double = 0.006
    @AppStorage("platformBaseDeduction") var platformBaseDeduction: Double = 0.037
    @AppStorage("rebateFrameworkFee") var rebateFrameworkFee: Double = 0.025
    @AppStorage("reducedDeduction") var reducedDeduction: Double = 0.014
    @AppStorage("cpsBaseCommissionExternal") var cpsBaseCommissionExternal: Double = 0.03
    
    func getTierRate(_ tier: ProductTier) -> Double {
        switch tier {
        case .lowWall: return rateLowWall
        case .lowCabinet: return rateLowCabinet
        case .ordinary: return rateOrdinary
        case .midRange: return rateMidRange
        case .highRange: return rateHighRange
        }
    }
}
