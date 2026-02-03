import SwiftUI

struct ProductListView: View {
    @State private var products = Product.sampleData()
    @State private var selectedProduct: Product.ID?
    @State private var searchText = ""
    
    var body: some View {
        Table(products, selection: $selectedProduct) {
            TableColumn("产品系列", value: \.name)
            TableColumn("型号", value: \.model)
            TableColumn("类型", value: \.type)
            TableColumn("档次") { product in
                Text(product.tier.rawValue)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            TableColumn("指导价") { product in
                Text(product.price, format: .currency(code: "CNY"))
            }
            TableColumn("国补到手") { product in
                Text(product.subsidyPrice, format: .currency(code: "CNY"))
                    .foregroundColor(.green)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("京东开团清单")
    }
}
