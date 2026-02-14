import SwiftUI

struct SetPasswordView: View {
    let passwordService: PasswordService
    let onSuccess: () -> Void

    @State private var step: PasswordStep = .enter
    @State private var firstPassword = ""
    @State private var currentInput = ""
    @State private var errorMessage: String?
    @State private var shake = false
    @Environment(\.dismiss) private var dismiss

    enum PasswordStep {
        case enter
        case confirm
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                titleSection

                dotsSection

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
            .navigationTitle(String(localized: "password_set_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        Text(step == .enter
             ? String(localized: "password_enter_prompt")
             : String(localized: "password_confirm_prompt"))
            .font(AppTypography.title2)
            .foregroundColor(AppColors.textPrimary)
    }

    private var dotsSection: some View {
        HStack(spacing: AppSpacing.lg) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < currentInput.count ? AppColors.primary : AppColors.divider)
                    .frame(width: 16, height: 16)
            }
        }
        .offset(x: shake ? -10 : 0)
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

    // MARK: - Logic

    private func handleInput(_ digit: String) {
        guard currentInput.count < 4 else { return }
        currentInput += digit
        errorMessage = nil

        if currentInput.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                processComplete()
            }
        }
    }

    private func processComplete() {
        switch step {
        case .enter:
            firstPassword = currentInput
            currentInput = ""
            withAnimation {
                step = .confirm
            }
        case .confirm:
            if currentInput == firstPassword {
                let success = passwordService.setPassword(currentInput)
                if success {
                    onSuccess()
                    dismiss()
                } else {
                    showError(String(localized: "error_save_failed"))
                }
            } else {
                showError(String(localized: "password_mismatch"))
                currentInput = ""
                withAnimation {
                    step = .enter
                }
                firstPassword = ""
            }
        }
    }

    private func showError(_ message: String) {
        withAnimation(.default) {
            errorMessage = message
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shake = false
        }
    }
}
