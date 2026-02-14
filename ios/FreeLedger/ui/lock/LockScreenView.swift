import SwiftUI

struct LockScreenView: View {
    let passwordService: PasswordService
    let onUnlocked: () -> Void

    @State private var currentInput = ""
    @State private var errorMessage: String?
    @State private var shake = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.primary)

                Text("FreeLedger")
                    .font(AppTypography.title1)
                    .foregroundColor(AppColors.textPrimary)

                Text(String(localized: "lock_enter_password"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: AppSpacing.xl) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < currentInput.count ? AppColors.primary : AppColors.divider)
                            .frame(width: 14, height: 14)
                            .scaleEffect(index < currentInput.count ? 1.2 : 1.0)
                            .animation(.spring(response: 0.2), value: currentInput.count)
                    }
                }
                .offset(x: shake ? -10 : 0)

                if let error = errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.expense)
                        .transition(.opacity)
                }

                Spacer()

                numberPad
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private var numberPad: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: AppSpacing.xl) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        numberButton(String(number))
                    }
                }
            }
            HStack(spacing: AppSpacing.xl) {
                Color.clear.frame(width: 72, height: 56)
                numberButton("0")
                Button {
                    if !currentInput.isEmpty {
                        currentInput.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 72, height: 56)
                }
            }
        }
    }

    private func numberButton(_ number: String) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            handleInput(number)
        } label: {
            Text(number)
                .font(AppTypography.keypadNumber)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 72, height: 56)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func handleInput(_ digit: String) {
        guard currentInput.count < 4 else { return }
        currentInput += digit
        errorMessage = nil

        if currentInput.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if passwordService.verifyPassword(currentInput) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onUnlocked()
                    }
                } else {
                    withAnimation(.default) {
                        errorMessage = String(localized: "password_wrong")
                    }
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) {
                        shake = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shake = false
                    }
                    currentInput = ""
                }
            }
        }
    }
}
