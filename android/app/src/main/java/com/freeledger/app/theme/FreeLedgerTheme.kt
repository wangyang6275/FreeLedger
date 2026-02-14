package com.freeledger.app.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val FreeLedgerColorScheme = lightColorScheme(
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
fun FreeLedgerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = FreeLedgerColorScheme,
        content = content
    )
}
