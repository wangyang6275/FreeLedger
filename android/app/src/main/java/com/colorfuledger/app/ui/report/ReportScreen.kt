package com.colorfuledger.app.ui.report

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.colorfuledger.app.R
import com.colorfuledger.app.theme.AppColors
import com.colorfuledger.app.theme.AppSpacing
import com.colorfuledger.app.theme.AppTypography

@Composable
fun ReportScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(AppSpacing.Xl),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stringResource(R.string.report_empty_state),
            style = AppTypography.Body,
            color = AppColors.TextSecondary
        )
    }
}
