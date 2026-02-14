import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(L("a11y_add_transaction"))
    }
}

#Preview {
    FloatingAddButton { }
}
