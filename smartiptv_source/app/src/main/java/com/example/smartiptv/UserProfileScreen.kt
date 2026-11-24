package com.example.smartiptv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

@Composable
fun UserProfileScreen(
    activationCode: String,
    onSignOut: () -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    var userInfo by remember { mutableStateOf<JSONObject?>(null) }
    var serverInfo by remember { mutableStateOf<JSONObject?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    fun formatTimestamp(timestampStr: String?): String {
        if (timestampStr.isNullOrEmpty() || timestampStr == "null" || timestampStr == "0") return "غير محدود"
        return try {
            val timestamp = timestampStr.toLong() * 1000L
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH)
            sdf.format(Date(timestamp))
        } catch (_: Exception) {
            timestampStr
        }
    }

    fun calculateDaysLeft(expTimestampStr: String?): String {
        if (expTimestampStr.isNullOrEmpty() || expTimestampStr == "null" || expTimestampStr == "0") return "غير محدود"
        return try {
            val expTime = expTimestampStr.toLong() * 1000L
            val currentTime = System.currentTimeMillis()
            val diff = expTime - currentTime
            val days = TimeUnit.MILLISECONDS.toDays(diff)
            if (days > 0) "$days Days" else "منتهي"
        } catch (_: Exception) {
            "N/A"
        }
    }

    LaunchedEffect(Unit) {
        // تنفيذ طلب الشبكة في الخلفية لعدم تجميد التطبيق أو إرجاع بيانات فارغة
        val response = withContext(Dispatchers.IO) {
            IptvApiClient.verifyActivationCode(context, activationCode)
        }
        try {
            val json = JSONObject(response)
            userInfo = json.optJSONObject("user_info")
            serverInfo = json.optJSONObject("server_info")
        } catch (_: Exception) {}
        isLoading = false
    }

    val expTimestamp = userInfo?.optString("exp_date")
    val createdTimestamp = userInfo?.optString("created_at")
    val formattedExpDate = formatTimestamp(expTimestamp)
    val formattedCreatedDate = formatTimestamp(createdTimestamp)
    val daysLeftText = calculateDaysLeft(expTimestamp)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F111A))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // شريط علوي مع زر الرجوع واسم المستخدم
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Button(
                    onClick = onBack,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1F222A))
                ) {
                    Text("← العودة للرئيسية", color = Color.White)
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF3B82F6)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = userInfo?.optString("username")?.take(1) ?: "U",
                            color = Color.White,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = userInfo?.optString("username") ?: activationCode,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Color(0xFF3B82F6))
                }
            } else {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // البطاقة الجانبية للمستخدم
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF161922)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(64.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF3B82F6)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = userInfo?.optString("username")?.take(1) ?: "9",
                                    color = Color.White,
                                    fontSize = 24.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = userInfo?.optString("username") ?: activationCode,
                                color = Color.White,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                ProfileBadge(text = userInfo?.optString("status") ?: "Active", color = Color(0xFF10B981))
                                ProfileBadge(text = "Web Player", color = Color(0xFF8B5CF6))
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                StatBox(title = "CONNECTIONS", value = "${userInfo?.optString("active_cons", "0")}/${userInfo?.optString("max_connections", "1")}")
                                StatBox(title = "DAYS LEFT", value = daysLeftText)
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = onSignOut,
                                modifier = Modifier.fillMaxWidth(),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7F1D1D)),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text("تسجيل خروج (Sign Out)", color = Color.White)
                            }
                        }
                    }

                    // قسم تفاصيل الاشتراك (Subscription)
                    ProfileSectionCard(title = "Subscription") {
                        ProfileInfoRow("Status", userInfo?.optString("status", "Active"), Color(0xFF10B981))
                        ProfileInfoRow("Expires", formattedExpDate, Color.White)
                        ProfileInfoRow("Time Remaining", daysLeftText, Color(0xFF10B981))
                        ProfileInfoRow("Trial Account", if (userInfo?.optString("is_trial") == "1") "Yes" else "No", Color.White)
                        ProfileInfoRow("Active connections", "${userInfo?.optString("active_cons", "0")} / ${userInfo?.optString("max_connections", "1")}", Color.White)
                    }

                    // قسم السيرفر (Server)
                    ProfileSectionCard(title = "Server") {
                        ProfileInfoRow("Host", serverInfo?.optString("url", "169.58.114.30"), Color.White)
                        ProfileInfoRow("Protocol", serverInfo?.optString("server_protocol", "http"), Color.White)
                        ProfileInfoRow("Server Time", serverInfo?.optString("time_now", "N/A"), Color.White)
                        ProfileInfoRow("Timezone", serverInfo?.optString("timezone", "Asia/Bahrain"), Color.White)
                    }

                    // قسم التشغيل (Playback)
                    ProfileSectionCard(title = "Playback") {
                        ProfileInfoRow("Username", userInfo?.optString("username") ?: activationCode, Color.White)
                        ProfileInfoRow("Output Formats", "M3U8, TS, RTMP", Color(0xFF3B82F6))
                        ProfileInfoRow("Created", formattedCreatedDate, Color.White)
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileBadge(text: String, color: Color) {
    Surface(
        color = color.copy(alpha = 0.2f),
        shape = RoundedCornerShape(4.dp)
    ) {
        Text(
            text = text,
            color = color,
            fontSize = 12.sp,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun StatBox(title: String, value: String) {
    Column(
        modifier = Modifier
            .background(Color(0xFF1F222A), RoundedCornerShape(8.dp))
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = title, color = Color.Gray, fontSize = 10.sp)
        Spacer(modifier = Modifier.height(4.dp))
        Text(text = value, color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun ProfileSectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF161922)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider(color = Color(0xFF2A2E39), thickness = 1.dp)
            Spacer(modifier = Modifier.height(12.dp))
            content()
        }
    }
}

@Composable
fun ProfileInfoRow(label: String, value: String?, valueColor: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, color = Color.Gray, fontSize = 14.sp)
        Text(text = value ?: "-", color = valueColor, fontSize = 14.sp, fontWeight = FontWeight.Medium)
    }
}