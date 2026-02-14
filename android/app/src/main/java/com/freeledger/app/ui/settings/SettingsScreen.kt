package com.freeledger.app.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.freeledger.app.R
import com.freeledger.app.theme.AppSpacing
import com.freeledger.app.theme.AppTypography

@Composable
fun SettingsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(AppSpacing.Xl)
    ) {
        Text(
            text = stringResource(R.string.tab_settings),
            style = AppTypography.Title1
        )
    }
}
