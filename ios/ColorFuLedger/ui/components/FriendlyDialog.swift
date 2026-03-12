import SwiftUI

enum FriendlyDialogStyle {
    case info
    case confirm
    case destructive
}

struct FriendlyDialog: View {
    let title: String
    let message: String
    let style: FriendlyDialogStyle
    let confirmTitle: String
    var cancelTitle: String? = nil
    let onConfirm: () -> Void
    var onCancel: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel?()
                }
                .transition(.opacity)

            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(message)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: AppSpacing.md) {
                    if let cancelTitle = cancelTitle {
                        Button(action: { onCancel?() }) {
                            Text(cancelTitle)
                                .font(AppTypography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.divider)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        }
                    }

                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(confirmButtonColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    }
                }
            }
            .padding(AppSpacing.xl)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .padding(.horizontal, AppSpacing.xxl)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
            .accessibilityElement(children: .contain)
        }
    }

    private var confirmButtonColor: Color {
        switch style {
        case .info: AppColors.primary
        case .confirm: AppColors.primary
        case .destructive: AppColors.expense
        }
    }
}
