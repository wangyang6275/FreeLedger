package com.colorfuledger.app.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val ColorFuLedgerColorScheme = lightColorScheme(
    primary = AppColors.Primary,
    onPrimary = AppColors.Surface,
    secondary = AppColors.Secondary,
    onSecondary = AppColors.Surface,
    background = AppColors.Background,
    onBackground = AppColors.TextPrimary,
    surface = AppColors.Surface,
    onSurface = AppColors.TextPrimary,
    error = AppColors.Error,
    onError = AppColors.Surface
)

@Composable
fun ColorFuLedgerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = ColorFuLedgerColorScheme,
        content = content
    )
}
