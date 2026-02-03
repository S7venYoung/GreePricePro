import Foundation

struct Product: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let model: String
    let price: Double
    let subsidyPrice: Double
    let tier: ProductTier
    let type: String
    
    static func sampleData() -> [Product] {
        return [
            Product(name: "云佳Pro26", model: "KFR-26GW/NhMa1BG", price: 2999, subsidyPrice: 2549.15, tier: .lowWall, type: "挂机"),
            Product(name: "云佳Pro35", model: "KFR-35GW/NhMa1BG", price: 3199, subsidyPrice: 2719.15, tier: .lowWall, type: "挂机"),
            Product(name: "云锦Pro26", model: "KFR-26GW/NhMb1BG", price: 3662, subsidyPrice: 3112.7, tier: .midRange, type: "挂机"),
            Product(name: "全能王50", model: "KFR-50LW/NhQa1BG", price: 10999, subsidyPrice: 9499, tier: .highRange, type: "柜机")
        ]
    }
}
