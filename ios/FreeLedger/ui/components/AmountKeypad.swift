import SwiftUI

struct AmountKeypad: View {
    @Binding var amountString: String
    var onTagTap: (() -> Void)?

    private let keys: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.digit("."), .digit("0"), .backspace]
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key) {
                            handleKeyPress(key)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    private func handleKeyPress(_ key: KeypadKey) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        switch key {
        case .digit(let d):
            appendDigit(d)
        case .backspace:
            if !amountString.isEmpty {
                amountString.removeLast()
            }
        case .tag:
            onTagTap?()
        }
    }

    private func appendDigit(_ digit: String) {
        if digit == "." {
            guard !amountString.contains(".") else { return }
            if amountString.isEmpty {
                amountString = "0."
                return
            }
        }

        if let dotIndex = amountString.firstIndex(of: ".") {
            let decimals = amountString[amountString.index(after: dotIndex)...]
            guard decimals.count < 2 else { return }
        }

        let integerPart: String
        if let dotIndex = amountString.firstIndex(of: ".") {
            integerPart = String(amountString[..<dotIndex])
        } else {
            integerPart = amountString
        }

        if digit != "." && !amountString.contains(".") {
            guard integerPart.count < 6 else { return }
        }

        amountString.append(digit)
    }
}

enum KeypadKey: Hashable {
    case digit(String)
    case backspace
    case tag
}

struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch key {
                case .digit(let d):
                    if d == "." {
                        Text(".")
                            .font(AppTypography.keypadNumber)
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text(d)
                            .font(AppTypography.keypadNumber)
                            .foregroundColor(AppColors.textPrimary)
                    }
                case .backspace:
                    Image(systemName: "delete.backward")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                case .tag:
                    Image(systemName: "tag")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch key {
        case .digit(let d):
            return d == "." ? String(localized: "a11y_decimal_point") : String(localized: "a11y_digit_\(d)")
        case .backspace:
            return String(localized: "a11y_backspace")
        case .tag:
            return String(localized: "a11y_tag_button")
        }
    }
}

#Preview {
    AmountKeypad(amountString: .constant("12.50"))
        .background(AppColors.background)
}
