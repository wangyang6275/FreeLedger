import SwiftUI

struct CategoryIconView: View {
    let iconName: String
    let colorHex: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: size, height: size)

            iconImage
                .font(.system(size: iconSize))
                .foregroundColor(Color(hex: "#2D3436").opacity(0.75))
        }
    }

    @ViewBuilder
    private var iconImage: some View {
        switch iconName {
        case "CoffeeOutlined": Image(systemName: "cup.and.saucer")
        case "ShoppingCartOutlined": Image(systemName: "cart")
        case "CarOutlined": Image(systemName: "car")
        case "HomeOutlined": Image(systemName: "house")
        case "MobileOutlined": Image(systemName: "iphone")
        case "PlayCircleOutlined": Image(systemName: "play.circle")
        case "SkinOutlined": Image(systemName: "tshirt")
        case "MedicineBoxOutlined": Image(systemName: "cross.case")
        case "ReadOutlined": Image(systemName: "book")
        case "GlobalOutlined": Image(systemName: "globe")
        case "SmileOutlined": Image(systemName: "face.smiling")
        case "WalletOutlined": Image(systemName: "wallet.pass")
        case "LaptopOutlined": Image(systemName: "laptopcomputer")
        case "RiseOutlined": Image(systemName: "chart.line.uptrend.xyaxis")
        case "GiftOutlined": Image(systemName: "gift")
        case "EllipsisOutlined": Image(systemName: "ellipsis")
        default: Image(systemName: "questionmark.circle")
        }
    }
}
