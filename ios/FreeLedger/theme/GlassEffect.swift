import SwiftUI

// MARK: - Apple Liquid Glass (Native iOS 26+ API)

/// 液态玻璃卡片 —— iOS 26+ 使用原生 .glassEffect()，旧版降级为 ultraThinMaterial
struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if ThemeManager.shared.isGlassTheme {
            if #available(iOS 26.0, *) {
                // 原生 Apple Liquid Glass —— 真正的折射、高光、光散射
                content
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                // iOS < 26 降级：ultraThinMaterial + 微妙渐变 + 细描边
                content
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                .linearGradient(
                                    colors: [
                                        .primary.opacity(0.08),
                                        .primary.opacity(0.05),
                                        .primary.opacity(0.01),
                                        .clear, .clear, .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.primary.opacity(0.2), lineWidth: 0.7)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            }
        } else {
            content
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
    }
}

/// 液态玻璃摘要卡片 —— iOS 26+ 使用带主题色着色的原生液态玻璃
struct GlassSummaryCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if ThemeManager.shared.isGlassTheme {
            if #available(iOS 26.0, *) {
                // 原生液态玻璃 + 主题色着色
                content
                    .glassEffect(
                        .regular.tint(Color(hex: ThemeManager.shared.colors.gradientStart)).interactive(),
                        in: .rect(cornerRadius: cornerRadius)
                    )
            } else {
                // iOS < 26 降级
                content
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(AppColors.primaryGradient)
                            .opacity(0.6)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.white.opacity(0.3), lineWidth: 0.7)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            }
        } else {
            content
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Glass Page Background

/// 液态玻璃主题的页面背景
struct GlassPageBackground: View {
    var body: some View {
        if ThemeManager.shared.isGlassTheme {
            // 干净的系统背景色 —— 让原生液态玻璃效果自然呈现
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        } else {
            AppColors.background
                .ignoresSafeArea()
        }
    }
}

// MARK: - View Extensions

extension View {
    /// 应用液态玻璃卡片效果
    func glassCard(cornerRadius: CGFloat = AppRadius.md) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    /// 应用液态玻璃摘要卡片效果
    func glassSummaryCard(cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(GlassSummaryCardModifier(cornerRadius: cornerRadius))
    }
}
