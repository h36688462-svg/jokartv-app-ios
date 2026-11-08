package com.example.smartiptv

import android.content.Context
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.example.smartiptv.ui.components.PinDialog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sharedPreferences = getSharedPreferences("IPTV_Prefs", Context.MODE_PRIVATE)
        val savedCode = sharedPreferences.getString("activation_code", null)

        setContent {
            Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                var isLoggedIn by remember { mutableStateOf(savedCode != null) }
                var activeActivationCode by remember { mutableStateOf(savedCode ?: "") }
                
                var activeCategory by remember { mutableStateOf<Triple<String, String, String>?>(null) } 
                var selectedStream by remember { mutableStateOf<StreamItem?>(null) }
                var selectedSeries by remember { mutableStateOf<StreamItem?>(null) }
                var showProfile by remember { mutableStateOf(false) }
                var showSettings by remember { mutableStateOf(false) }
                var currentTab by remember { mutableStateOf("movies") }
                
                var pendingCategory by remember { mutableStateOf<Triple<String, String, String>?>(null) }
                var showPinDialog by remember { mutableStateOf(false) }

                val coroutineScope = rememberCoroutineScope()

                if (!isLoggedIn) {
                    LoginScreen(onLoginCodeSubmitted = { code ->
                        coroutineScope.launch {
                            val result = withContext(Dispatchers.IO) {
                                IptvApiClient.verifyActivationCode(this@MainActivity, code)
                            }
                            if (result.contains("user_info")) {
                                sharedPreferences.edit().putString("activation_code", code).apply()
                                activeActivationCode = code
                                isLoggedIn = true
                            } else {
                                withContext(Dispatchers.Main) {
                                    Toast.makeText(this@MainActivity, "Error: $result", Toast.LENGTH_LONG).show()
                                }
                            }
                        }
                    })
                } else {
                    if (showPinDialog) {
                        PinDialog(
                            onDismiss = { showPinDialog = false },
                            onConfirm = { pin ->
                                if (ParentalControlManager.validatePin(this@MainActivity, pin)) {
                                    activeCategory = pendingCategory
                                    showPinDialog = false
                                } else {
                                    Toast.makeText(this@MainActivity, "Invalid PIN", Toast.LENGTH_SHORT).show()
                                }
                            }
                        )
                    }

                    when {
                        showSettings -> {
                            SettingsScreen(onBack = { showSettings = false })
                        }
                        showProfile -> {
                            UserProfileScreen(
                                activationCode = activeActivationCode,
                                onSignOut = {
                                    sharedPreferences.edit().remove("activation_code").apply()
                                    isLoggedIn = false
                                    showProfile = false
                                },
                                onBack = { showProfile = false }
                            )
                        }
                        selectedStream != null -> {
                            PlayerScreen(
                                streamId = selectedStream!!.streamId,
                                streamType = selectedStream!!.streamType,
                                streamName = selectedStream!!.name,
                                onBack = { selectedStream = null }
                            )
                        }
                        selectedSeries != null -> {
                            SeriesDetailScreen(
                                seriesId = selectedSeries!!.streamId,
                                seriesName = selectedSeries!!.name,
                                onEpisodeSelected = { stream -> selectedStream = stream },
                                onBack = { selectedSeries = null }
                            )
                        }
                        activeCategory != null -> {
                            StreamsScreen(
                                categoryType = activeCategory!!.third,
                                categoryId = activeCategory!!.first,
                                categoryName = activeCategory!!.second,
                                onStreamSelected = { stream ->
                                    if (stream.streamType == "series") selectedSeries = stream
                                    else selectedStream = stream
                                },
                                onBack = { activeCategory = null }
                            )
                        }
                        else -> {
                            NetflixDashboardScreen(
                                selectedTab = currentTab,
                                onTabSelected = { newTab -> currentTab = newTab },
                                onCategorySelected = { catId, catType, catName ->
                                    val cat = Triple(catId, catName, catType)
                                    if (ParentalControlManager.isCategoryLocked(this@MainActivity, catName)) {
                                        pendingCategory = cat
                                        showPinDialog = true
                                    } else {
                                        activeCategory = cat
                                    }
                                },
                                onProfileClicked = { showProfile = true },
                                onSettingsClicked = { showSettings = true },
                                onStreamSelected = { stream ->
                                    if (stream.streamType == "series") selectedSeries = stream
                                    else selectedStream = stream
                                },
                                onBack = { finish() }
                            )
                        }
                    }
                }
            }
        }
    }
}