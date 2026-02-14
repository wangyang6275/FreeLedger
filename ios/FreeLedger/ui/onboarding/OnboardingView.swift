import SwiftUI

struct OnboardingView: View {
    let settingsRepository: SettingsRepositoryProtocol
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var selectedCurrency: String
    @State private var iconAnimated = false

    private let currencies = ["CNY", "USD", "EUR", "GBP", "JPY", "KRW", "HKD", "TWD"]

    init(settingsRepository: SettingsRepositoryProtocol, onComplete: @escaping () -> Void) {
        self.settingsRepository = settingsRepository
        self.onComplete = onComplete
        let systemCurrency = Locale.current.currency?.identifier ?? "CNY"
        _selectedCurrency = State(initialValue: systemCurrency)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    step1View.tag(0)
                    step2View.tag(1)
                    step3View.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                bottomButtons
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    // MARK: - Step 1

    private var step1View: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 72))
                .foregroundColor(AppColors.primary)
                .scaleEffect(iconAnimated ? 1.0 : 0.3)
                .opacity(iconAnimated ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: iconAnimated)

            Text(String(localized: "onboarding_step1_title"))
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(iconAnimated ? 1.0 : 0.0)
                .offset(y: iconAnimated ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: iconAnimated)

            Text(String(localized: "onboarding_step1_desc"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
                .opacity(iconAnimated ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: iconAnimated)

            Spacer()
            Spacer()
        }
        .onAppear {
            iconAnimated = true
        }
    }

    // MARK: - Step 2

    private var step2View: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.secondary)
                .padding(.top, AppSpacing.xxxl)

            Text(String(localized: "onboarding_step2_title"))
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)

            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(currencies, id: \.self) { code in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCurrency = code
                            }
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Text(currencySymbol(code))
                                    .font(.system(size: 20, weight: .medium))
                                    .frame(width: 32)

                                Text(currencyDisplayName(code))
                                    .font(AppTypography.bodyLarge)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if selectedCurrency == code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, 14)
                            .background(selectedCurrency == code ? AppColors.primaryLight : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Step 3

    private var step3View: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(AppColors.primary)

            Text(String(localized: "onboarding_step3_title"))
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "onboarding_step3_desc"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom

    private var bottomButtons: some View {
        VStack(spacing: AppSpacing.md) {
            if currentPage == 2 {
                Button {
                    completeOnboarding()
                } label: {
                    Text(String(localized: "onboarding_start"))
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            } else {
                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    Text(String(localized: "onboarding_next"))
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }

            Button {
                completeOnboarding()
            } label: {
                Text(String(localized: "onboarding_skip"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Logic

    private func completeOnboarding() {
        try? settingsRepository.set(key: "currency", value: selectedCurrency)
        try? settingsRepository.set(key: "onboarding_completed", value: "true")
        onComplete()
    }

    private func currencyDisplayName(_ code: String) -> String {
        let locale = Locale.current
        let name = locale.localizedString(forCurrencyCode: code) ?? code
        return "\(code) - \(name)"
    }

    private func currencySymbol(_ code: String) -> String {
        switch code {
        case "CNY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "KRW": return "₩"
        case "HKD": return "HK$"
        case "TWD": return "NT$"
        default: return code
        }
    }
}
