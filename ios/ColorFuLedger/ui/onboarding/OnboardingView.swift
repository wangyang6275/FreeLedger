import SwiftUI

struct OnboardingView: View {
    let settingsRepository: SettingsRepositoryProtocol
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var selectedCurrency: String
    @State private var welcomeAnimated = false
    @State private var languageManager = LanguageManager.shared

    private let totalPages = 5
    private let currencies = ["CNY", "USD", "EUR", "GBP", "JPY", "KRW", "HKD", "TWD"]

    // 语言选择页展示的主要语言（最常用的放前面）
    private let featuredLanguages = [
        "zh-Hans", "zh-Hant", "en", "ja", "ko",
        "fr", "de", "es", "pt-BR", "ru",
        "ar", "it", "hi", "id", "tr",
        "vi", "th", "nl", "pl", "ms",
        "sv", "uk", "he"
    ]

    init(settingsRepository: SettingsRepositoryProtocol, onComplete: @escaping () -> Void) {
        self.settingsRepository = settingsRepository
        self.onComplete = onComplete
        let systemCurrency = Locale.current.currency?.identifier ?? "CNY"
        let supported = ["CNY", "USD", "EUR", "GBP", "JPY", "KRW", "HKD", "TWD"]
        _selectedCurrency = State(initialValue: supported.contains(systemCurrency) ? systemCurrency : "CNY")
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 页面内容区：用 id 强制在语言切换后重新渲染
                TabView(selection: $currentPage) {
                    languageStep.tag(0)
                    welcomeStep.tag(1)
                    currencyStep.tag(2)
                    tourStep.tag(3)
                    readyStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .id(languageManager.refreshId)   // 语言切换时强制重建

                bottomBar
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    // MARK: - Step 0: 语言选择

    private var languageStep: some View {
        VStack(spacing: 0) {
            // 顶部标题区（多语言同时展示，让用户能认出自己的语言）
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "globe")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, AppSpacing.xxxl)
                    .padding(.bottom, AppSpacing.sm)

                // 用多语言展示标题，让任何语言的用户都能看懂
                VStack(spacing: 4) {
                    Text("选择语言 · Select Language")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Choisir la langue · 言語を選択")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.bottom, AppSpacing.md)
            }

            // 语言列表
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(languageList, id: \.code) { lang in
                        languageRow(lang)
                        if lang.code != languageList.last?.code {
                            Divider()
                                .padding(.leading, 56)
                                .padding(.trailing, AppSpacing.lg)
                        }
                    }
                }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
            }
        }
    }

    private var languageList: [LanguageManager.Language] {
        featuredLanguages.compactMap { code in
            LanguageManager.supportedLanguages.first { $0.code == code }
        }
    }

    private func languageRow(_ lang: LanguageManager.Language) -> some View {
        let isSelected = languageManager.currentLanguage == lang.code
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                languageManager.currentLanguage = lang.code
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                // 语言首字母标识
                Text(lang.localName.prefix(2).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? AppColors.primary : AppColors.background)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.localName)
                        .font(AppTypography.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(AppColors.textPrimary)
                    Text(lang.name)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 1: 欢迎 + 核心价值

    private var welcomeStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                Spacer().frame(height: AppSpacing.xl)

                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 88, height: 88)
                        Image(systemName: "dollarsign")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(welcomeAnimated ? 1.0 : 0.5)
                    .opacity(welcomeAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: welcomeAnimated)

                    Text(L("onboarding_welcome_title"))
                        .font(AppTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(welcomeAnimated ? 1.0 : 0.0)
                        .offset(y: welcomeAnimated ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.15), value: welcomeAnimated)

                    Text(L("onboarding_welcome_subtitle"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(welcomeAnimated ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.45).delay(0.25), value: welcomeAnimated)
                }

                // 4 核心卖点
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        featureCard(icon: "bolt.fill",       color: "#FF9500",
                                    title: L("onboarding_feat_fast_title"),    desc: L("onboarding_feat_fast_desc"))
                        featureCard(icon: "wifi.slash",      color: "#34C759",
                                    title: L("onboarding_feat_offline_title"), desc: L("onboarding_feat_offline_desc"))
                    }
                    HStack(spacing: AppSpacing.sm) {
                        featureCard(icon: "lock.shield.fill", color: "#5856D6",
                                    title: L("onboarding_feat_privacy_title"), desc: L("onboarding_feat_privacy_desc"))
                        featureCard(icon: "gift.fill",        color: "#FF6B6B",
                                    title: L("onboarding_feat_free_title"),    desc: L("onboarding_feat_free_desc"))
                    }
                }
                .opacity(welcomeAnimated ? 1.0 : 0.0)
                .offset(y: welcomeAnimated ? 0 : 24)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: welcomeAnimated)
                .padding(.horizontal, AppSpacing.lg)

                Spacer().frame(height: AppSpacing.xxl)
            }
        }
        .onAppear {
            welcomeAnimated = true
        }
    }

    private func featureCard(icon: String, color: String, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: color))
            }
            Text(title)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            Text(desc)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Step 2: 货币选择

    private var currencyStep: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 52))
                    .foregroundColor(AppColors.secondary)
                    .padding(.top, AppSpacing.xxxl)

                Text(L("onboarding_step2_title"))
                    .font(AppTypography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)

                Text(L("onboarding_step2_subtitle"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(currencies, id: \.self) { code in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCurrency = code
                            }
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Text(currencySymbol(code))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(selectedCurrency == code ? AppColors.primary : AppColors.textSecondary)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(code)
                                        .font(AppTypography.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(Locale.current.localizedString(forCurrencyCode: code) ?? code)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }

                                Spacer()

                                if selectedCurrency == code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppColors.primary)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .background(selectedCurrency == code ? AppColors.primary.opacity(0.08) : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(selectedCurrency == code ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Step 3: 功能速览

    private var tourStep: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary)

                Text(L("onboarding_step3_title"))
                    .font(AppTypography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L("onboarding_step3_subtitle"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            VStack(spacing: AppSpacing.md) {
                tourRow(icon: "plus.circle.fill",   color: AppColors.primary,
                        title: L("onboarding_tour1_title"), desc: L("onboarding_tour1_desc"))
                tourRow(icon: "chart.pie.fill",      color: AppColors.secondary,
                        title: L("onboarding_tour2_title"), desc: L("onboarding_tour2_desc"))
                tourRow(icon: "arrow.up.doc.fill",   color: Color(hex: "#5856D6"),
                        title: L("onboarding_tour3_title"), desc: L("onboarding_tour3_desc"))
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
            Spacer()
        }
    }

    private func tourRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                Text(desc)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }

    // MARK: - Step 4: 一切就绪

    private var readyStep: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(L("onboarding_ready_title"))
                    .font(AppTypography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L("onboarding_ready_desc"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            HStack(spacing: AppSpacing.lg) {
                readyTip(icon: "hand.tap.fill",  color: AppColors.primary,        text: L("onboarding_ready_tip1"))
                readyTip(icon: "eye.slash.fill", color: Color(hex: "#5856D6"),    text: L("onboarding_ready_tip2"))
                readyTip(icon: "star.fill",      color: Color(hex: "#FF9500"),    text: L("onboarding_ready_tip3"))
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
    }

    private func readyTip(icon: String, color: Color, text: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                if currentPage < totalPages - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage == totalPages - 1 ? L("onboarding_start") : L("onboarding_next"))
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }

            // 最后一页隐藏跳过
            if currentPage < totalPages - 1 {
                Button { completeOnboarding() } label: {
                    Text(L("onboarding_skip"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Logic

    private func completeOnboarding() {
        try? settingsRepository.set(key: "currency", value: selectedCurrency)
        try? settingsRepository.set(key: "onboarding_completed", value: "true")
        onComplete()
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
