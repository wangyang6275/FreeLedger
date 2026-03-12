package com.colorfuledger.app.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.colorfuledger.app.R
import com.colorfuledger.app.theme.AppColors
import com.colorfuledger.app.ui.home.HomeScreen
import com.colorfuledger.app.ui.report.ReportScreen
import com.colorfuledger.app.ui.settings.SettingsScreen
import com.colorfuledger.app.ui.tags.TagsScreen

@Composable
fun AppNavigation() {
    var selectedTab by remember { mutableIntStateOf(0) }
    val addLabel = stringResource(R.string.a11y_add_transaction)

    Scaffold(
        bottomBar = {
            NavigationBar(containerColor = AppColors.Surface) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(painterResource(R.drawable.ic_list), contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_transactions)) }
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(painterResource(R.drawable.ic_pie_chart), contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_reports)) }
                )
                NavigationBarItem(
                    selected = false,
                    onClick = { },
                    icon = { Box(Modifier.size(24.dp)) },
                    label = { Text("") },
                    enabled = false
                )
                NavigationBarItem(
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3 },
                    icon = { Icon(painterResource(R.drawable.ic_tag), contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_tags)) }
                )
                NavigationBarItem(
                    selected = selectedTab == 4,
                    onClick = { selectedTab = 4 },
                    icon = { Icon(painterResource(R.drawable.ic_settings), contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_settings)) }
                )
            }
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { /* Story 1.2 will implement */ },
                containerColor = AppColors.Primary,
                contentColor = Color.White,
                shape = CircleShape,
                modifier = Modifier.semantics { contentDescription = addLabel }
            ) {
                Icon(Icons.Outlined.Add, contentDescription = null)
            }
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (selectedTab) {
                0 -> HomeScreen()
                1 -> ReportScreen()
                3 -> TagsScreen()
                4 -> SettingsScreen()
            }
        }
    }
}
