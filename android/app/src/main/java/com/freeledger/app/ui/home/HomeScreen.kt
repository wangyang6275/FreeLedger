package com.freeledger.app.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.freeledger.app.R
import com.freeledger.app.theme.AppColors
import com.freeledger.app.theme.AppSpacing
import com.freeledger.app.theme.AppTypography

@Composable
fun HomeScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(AppSpacing.Xl),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stringResource(R.string.home_empty_state),
            style = AppTypography.Body,
            color = AppColors.TextSecondary
        )
    }
}
