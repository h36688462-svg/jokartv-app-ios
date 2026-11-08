package com.example.smartiptv

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.smartiptv.R

@Composable
fun SettingsScreen(onBack: () -> Unit) {
    var selectedCategory by remember { mutableStateOf("Playback") }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF050B18))
    ) {
        Row(modifier = Modifier.fillMaxSize()) {
            // Sidebar
            Column(
                modifier = Modifier
                    .width(240.dp)
                    .fillMaxHeight()
                    .background(Color(0xFF0F172A))
                    .padding(vertical = 24.dp)
            ) {
                Text(
                    text = stringResource(R.string.settings),
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 16.dp)
                )

                val categories = listOf("Playback", "Display", "Privacy & Cache", "About")
                categories.forEach { category ->
                    var isFocused by remember { mutableStateOf(false) }
                    val isSelected = selectedCategory == category

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                            .onFocusChanged { isFocused = it.isFocused }
                            .focusable()
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (isSelected) Color(0xFF1E293B) else if (isFocused) Color(0x33FFFFFF) else Color.Transparent)
                            .clickable { selectedCategory = category }
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Text(
                            text = category,
                            color = if (isSelected) Color(0xFF3B82F6) else Color.White,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                            fontSize = 16.sp
                        )
                    }
                }
                
                Spacer(modifier = Modifier.weight(1f))
                
                TextButton(
                    onClick = onBack,
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text("← " + stringResource(R.string.back), color = Color.Gray)
                }
            }

            // Content Area
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(40.dp)
            ) {
                Text(
                    text = selectedCategory,
                    color = Color.White,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Control how your content plays",
                    color = Color.Gray,
                    fontSize = 14.sp
                )
                
                Spacer(modifier = Modifier.height(32.dp))

                when (selectedCategory) {
                    "Playback" -> PlaybackSettingsContent()
                    "Display" -> DisplaySettingsContent()
                    "Privacy & Cache" -> PrivacyCacheSettingsContent()
                    "About" -> AboutSettingsContent()
                }
            }
        }
    }
}

@Composable
fun PlaybackSettingsContent() {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SettingToggleRow(stringResource(R.string.autoplay_next), stringResource(R.string.autoplay_next_desc), true)
        SettingDropdownRow(stringResource(R.string.default_format), stringResource(R.string.default_format_desc), "HLS (.m3u8)")
        SettingDropdownRow(stringResource(R.string.default_volume), stringResource(R.string.default_volume_desc), "100%")
        SettingToggleRow(stringResource(R.string.resume_watching), stringResource(R.string.resume_watching_desc), true)
    }
}

@Composable
fun DisplaySettingsContent() {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SettingDropdownRow(stringResource(R.string.grid_size), stringResource(R.string.grid_size_desc), stringResource(R.string.auto))
        SettingToggleRow(stringResource(R.string.show_ratings), stringResource(R.string.show_ratings_desc), true)
    }
}

@Composable
fun PrivacyCacheSettingsContent() {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SettingActionRow(stringResource(R.string.clear_history), stringResource(R.string.clear_history_desc), stringResource(R.string.clear)) {
            // Logic to clear history
        }
        SettingActionRow(stringResource(R.string.clear_catalog), stringResource(R.string.clear_catalog_desc), stringResource(R.string.clear_cache)) {
            IptvCacheManager.clearAll()
        }
    }
}

@Composable
fun AboutSettingsContent() {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFF131C2E)),
        modifier = Modifier.fillMaxWidth().height(200.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(stringResource(R.string.about_title), color = Color(0xFF3B82F6), fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Text(stringResource(R.string.about_subtitle), color = Color.Gray, fontSize = 14.sp)
            Spacer(modifier = Modifier.height(20.dp))
            Text(
                stringResource(R.string.about_desc),
                color = Color.LightGray,
                fontSize = 16.sp,
                modifier = Modifier.padding(horizontal = 64.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

@Composable
fun SettingToggleRow(title: String, subtitle: String, initialValue: Boolean) {
    var checked by remember { mutableStateOf(initialValue) }
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(20.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(subtitle, color = Color.Gray, fontSize = 14.sp)
            }
            Switch(
                checked = checked, 
                onCheckedChange = { checked = it },
                colors = SwitchDefaults.colors(checkedThumbColor = Color(0xFF3B82F6))
            )
        }
    }
}

@Composable
fun SettingDropdownRow(title: String, subtitle: String, value: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(20.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(subtitle, color = Color.Gray, fontSize = 14.sp)
            }
            Box(
                modifier = Modifier
                    .background(Color(0xFF1E293B), RoundedCornerShape(6.dp))
                    .padding(horizontal = 16.dp, vertical = 10.dp)
            ) {
                Text(value, color = Color.White, fontSize = 16.sp)
            }
        }
    }
}

@Composable
fun SettingActionRow(title: String, subtitle: String, actionText: String, onClick: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(20.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(subtitle, color = Color.Gray, fontSize = 14.sp)
            }
            Button(
                onClick = onClick,
                colors = ButtonDefaults.buttonColors(containerColor = if (actionText.contains("cache", true)) Color(0xFF1E293B) else Color(0xFF7F1D1D)),
                shape = RoundedCornerShape(6.dp)
            ) {
                Text(actionText, color = Color.White)
            }
        }
    }
}
