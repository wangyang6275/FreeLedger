package com.colorfuledger.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.colorfuledger.app.theme.ColorFuLedgerTheme
import com.colorfuledger.app.ui.navigation.AppNavigation

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ColorFuLedgerTheme {
                AppNavigation()
            }
        }
    }
}
