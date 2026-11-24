package com.example.smartiptv

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage

@Composable
fun NetflixDashboardScreen(
    selectedTab: String,
    onTabSelected: (String) -> Unit,
    onCategorySelected: (String, String, String) -> Unit,
    onProfileClicked: () -> Unit,
    onSettingsClicked: () -> Unit,
    onStreamSelected: (StreamItem) -> Unit,
    onBack: () -> Unit,
    viewModel: DashboardViewModel = viewModel()
) {
    val context = LocalContext.current
    
    BackHandler {
        onBack()
    }

    LaunchedEffect(selectedTab) {
        viewModel.loadData(context, selectedTab)
    }

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0B0B0B))
    ) {
        val isWideScreen = maxWidth > 600.dp
        
        Column(modifier = Modifier.fillMaxSize()) {
            // Responsive Top Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF141414))
                    .padding(horizontal = if (isWideScreen) 32.dp else 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Larger and Clearer Logo (Point 4)
                Image(
                    painter = painterResource(id = R.drawable.app_logo),
                    contentDescription = "App Logo",
                    modifier = Modifier
                        .height(if (isWideScreen) 56.dp else 48.dp)
                        .width(if (isWideScreen) 140.dp else 120.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    contentScale = ContentScale.Fit
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(if (isWideScreen) 24.dp else 16.dp), 
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val tabs = listOf(
                        "movies" to stringResource(R.string.movies),
                        "series" to stringResource(R.string.series),
                        "live" to stringResource(R.string.tv_live),
                        "favorites" to stringResource(R.string.favorites)
                    )
                    tabs.forEach { (key, label) ->
                        var isFocused by remember { mutableStateOf(false) }
                        Box(
                            modifier = Modifier
                                .onFocusChanged { isFocused = it.isFocused }
                                .focusable()
                                .border(if (isFocused) 2.dp else 0.dp, Color.White, RoundedCornerShape(4.dp))
                                .padding(8.dp)
                                .clickable { onTabSelected(key) }
                        ) {
                            Text(
                                text = label,
                                color = if (selectedTab == key || isFocused) Color.White else Color.Gray,
                                fontWeight = FontWeight.Bold,
                                fontSize = if (isWideScreen) 18.sp else 15.sp
                            )
                        }
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onSettingsClicked) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings", tint = Color.White, modifier = Modifier.size(if (isWideScreen) 32.dp else 26.dp))
                    }
                    IconButton(onClick = onProfileClicked) {
                        Icon(Icons.Default.AccountCircle, contentDescription = "Profile", tint = Color.White, modifier = Modifier.size(if (isWideScreen) 32.dp else 26.dp))
                    }
                }
            }

            if (viewModel.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Color(0xFFE50914))
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(24.dp)
                ) {
                    // Feature Banner
                    if (viewModel.featuredItem != null && selectedTab != "favorites") {
                        item {
                            FeaturedBanner(
                                item = viewModel.featuredItem!!, 
                                isWideScreen = isWideScreen,
                                onPlay = {
                                    WatchHistoryManager.addToRecent(context, it)
                                    onStreamSelected(it)
                                }
                            )
                        }
                    }

                    // Continue Watching
                    if (viewModel.recentItems.isNotEmpty() && selectedTab == "movies") {
                        item {
                            DashboardRow(
                                title = stringResource(R.string.continue_watching), 
                                items = viewModel.recentItems, 
                                isWideScreen = isWideScreen,
                                onStreamSelected = onStreamSelected
                            )
                        }
                    }

                    // Content Rows
                    items(viewModel.categoriesData) { category ->
                        DashboardRow(
                            title = category.categoryName,
                            items = category.items,
                            isWideScreen = isWideScreen,
                            onStreamSelected = onStreamSelected,
                            onSeeAll = {
                                val currentType = when (selectedTab) {
                                    "series" -> "series"
                                    "live" -> "live"
                                    else -> "movies"
                                }
                                onCategorySelected(category.categoryId, currentType, category.categoryName)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun FeaturedBanner(item: StreamItem, isWideScreen: Boolean, onPlay: (StreamItem) -> Unit) {
    val context = LocalContext.current
    Box(modifier = Modifier.fillMaxWidth().height(if (isWideScreen) 500.dp else 380.dp)) {
        AsyncImage(
            model = item.streamIcon, 
            contentDescription = null, 
            contentScale = ContentScale.Crop, 
            modifier = Modifier.fillMaxSize()
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    androidx.compose.ui.graphics.Brush.verticalGradient(
                        listOf(Color.Transparent, Color(0xFF0B0B0B)),
                        startY = if (isWideScreen) 300f else 200f
                    )
                )
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(if (isWideScreen) 48.dp else 24.dp), 
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = item.name, 
                color = Color.White, 
                fontSize = if (isWideScreen) 42.sp else 28.sp, 
                fontWeight = FontWeight.Bold,
                maxLines = 2
            )
            Spacer(modifier = Modifier.height(16.dp))
            var isPlayFocused by remember { mutableStateOf(false) }
            Button(
                onClick = { 
                    WatchHistoryManager.addToRecent(context, item)
                    onPlay(item) 
                }, 
                colors = ButtonDefaults.buttonColors(containerColor = if (isPlayFocused) Color.Yellow else Color.White),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier
                    .height(if (isWideScreen) 64.dp else 48.dp)
                    .width(if (isWideScreen) 200.dp else 140.dp)
                    .onFocusChanged { isPlayFocused = it.isFocused }
                    .border(if (isPlayFocused) 3.dp else 0.dp, Color.Black, RoundedCornerShape(8.dp))
            ) {
                Text(
                    text = "▶ " + stringResource(R.string.play), 
                    color = Color.Black, 
                    fontWeight = FontWeight.Bold, 
                    fontSize = if (isWideScreen) 22.sp else 16.sp
                )
            }
        }
    }
}

@Composable
fun DashboardRow(
    title: String, 
    items: List<StreamItem>, 
    isWideScreen: Boolean,
    onStreamSelected: (StreamItem) -> Unit, 
    onSeeAll: (() -> Unit)? = null
) {
    val context = LocalContext.current
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = if (isWideScreen) 32.dp else 20.dp), 
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = title, color = Color.White, fontSize = if (isWideScreen) 24.sp else 20.sp, fontWeight = FontWeight.Bold)
            if (onSeeAll != null) {
                var isSeeAllFocused by remember { mutableStateOf(false) }
                Box(
                    modifier = Modifier
                        .onFocusChanged { isSeeAllFocused = it.isFocused }
                        .focusable()
                        .border(if (isSeeAllFocused) 2.dp else 0.dp, Color.Red, RoundedCornerShape(4.dp))
                        .padding(4.dp)
                        .clickable { onSeeAll() }
                ) {
                    Text(
                        text = stringResource(R.string.see_all), 
                        color = Color.Red, 
                        fontWeight = FontWeight.Bold,
                        fontSize = if (isWideScreen) 18.sp else 14.sp
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(12.dp))
        LazyRow(
            contentPadding = PaddingValues(horizontal = if (isWideScreen) 32.dp else 20.dp), 
            horizontalArrangement = Arrangement.spacedBy(if (isWideScreen) 20.dp else 12.dp)
        ) {
            items(items) { item ->
                var isFocused by remember { mutableStateOf(false) }
                Card(
                    modifier = Modifier
                        .width(if (isWideScreen) 200.dp else 130.dp)
                        .height(if (isWideScreen) 300.dp else 190.dp)
                        .onFocusChanged { isFocused = it.isFocused }
                        .focusable()
                        .border(if (isFocused) 3.dp else 0.dp, Color.White, RoundedCornerShape(8.dp))
                        .clickable { 
                            WatchHistoryManager.addToRecent(context, item)
                            onStreamSelected(item) 
                        },
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF1F1F1F)),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    AsyncImage(
                        model = item.streamIcon, 
                        contentDescription = null, 
                        contentScale = ContentScale.Crop, 
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
    }
}
