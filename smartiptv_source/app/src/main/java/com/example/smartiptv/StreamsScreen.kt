package com.example.smartiptv

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

@Composable
fun StreamsScreen(
    categoryType: String,
    categoryId: String,
    categoryName: String,
    onStreamSelected: (StreamItem) -> Unit,
    onBack: () -> Unit,
    viewModel: StreamsViewModel = viewModel()
) {
    val context = LocalContext.current
    var selectedItemForDetail by remember { mutableStateOf<StreamItem?>(null) }
    var searchQuery by remember { mutableStateOf("") }
    
    // IPTVX Sidebar categories state for live streams
    var currentCategoryId by remember { mutableStateOf(categoryId) }
    var currentCategoryName by remember { mutableStateOf(categoryName) }
    var categoriesList by remember { mutableStateOf<List<CategoryItem>>(emptyList()) }

    BackHandler {
        if (selectedItemForDetail != null) {
            selectedItemForDetail = null
        } else {
            onBack()
        }
    }

    LaunchedEffect(currentCategoryId, categoryType) {
        viewModel.loadStreams(context, categoryType, currentCategoryId)
        if (categoryType == "live") {
            withContext(Dispatchers.IO) {
                try {
                    val jsonStr = IptvApiClient.getCategories(context, "get_live_categories")
                    val arr = JSONArray(jsonStr)
                    val list = mutableListOf<CategoryItem>()
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        val id = obj.optString("category_id", "")
                        val name = obj.optString("category_name", "")
                        if (id.isNotEmpty()) {
                            list.add(CategoryItem(id, name))
                        }
                    }
                    categoriesList = list
                } catch (_: Exception) {}
            }
        }
    }

    val filteredStreams = viewModel.streamsList.filter { 
        it.name.contains(searchQuery, ignoreCase = true) 
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF050B18))
    ) {
        if (categoryType == "live") {
            // IPTVX Live TV Layout with Sidebar & Grid
            Row(modifier = Modifier.fillMaxSize()) {
                // Sidebar Categories Panel
                Surface(
                    modifier = Modifier
                        .width(280.dp)
                        .fillMaxHeight(),
                    color = Color(0xFF0F172A)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(onClick = onBack) {
                                Text("←", color = Color.White, fontSize = 20.sp)
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Live TV (IPTVX)",
                                color = Color.White,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Text(
                            text = "Categories",
                            color = Color(0xFF3B82F6),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 4.dp)
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(categoriesList) { cat ->
                                val isSelected = cat.categoryId == currentCategoryId
                                Surface(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { 
                                            currentCategoryId = cat.categoryId
                                            currentCategoryName = cat.categoryName
                                            searchQuery = ""
                                        },
                                    color = if (isSelected) Color(0xFF3B82F6) else Color(0xFF1E293B),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text(
                                        text = cat.categoryName,
                                        color = Color.White,
                                        fontSize = 14.sp,
                                        modifier = Modifier.padding(12.dp),
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }
                        }
                    }
                }

                // Main Content Area (Header + Search + Channel Grid)
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .padding(16.dp)
                ) {
                    // Top Bar with Category Name & Search Bar
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = currentCategoryName,
                            color = Color.White,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )

                        OutlinedTextField(
                            value = searchQuery,
                            onValueChange = { searchQuery = it },
                            placeholder = { Text("Search channel...", color = Color.Gray) },
                            singleLine = true,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Color(0xFF3B82F6),
                                unfocusedBorderColor = Color(0xFF334155),
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                cursorColor = Color(0xFF3B82F6)
                            ),
                            modifier = Modifier.width(260.dp),
                            shape = RoundedCornerShape(8.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    if (viewModel.isLoading) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(color = Color(0xFF3B82F6))
                        }
                    } else if (filteredStreams.isEmpty()) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(text = stringResource(R.string.no_content), color = Color.Gray)
                        }
                    } else {
                        LazyVerticalGrid(
                            columns = GridCells.Adaptive(minSize = 160.dp),
                            contentPadding = PaddingValues(bottom = 16.dp),
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(filteredStreams) { stream ->
                                LiveChannelCard(
                                    item = stream,
                                    onClick = { onStreamSelected(stream) }
                                )
                            }
                        }
                    }
                }
            }
        } else {
            // Standard VOD / Series Layout
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBack) {
                        Text("←", color = Color.White, fontSize = 24.sp)
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(
                        text = categoryName,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (viewModel.isLoading) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = Color(0xFF3B82F6))
                    }
                } else if (viewModel.streamsList.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(text = stringResource(R.string.no_content), color = Color.Gray)
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Adaptive(minSize = 140.dp),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(viewModel.streamsList) { stream ->
                            StreamGridItem(
                                item = stream,
                                onClick = { 
                                    if (stream.streamType == "live") {
                                        onStreamSelected(stream)
                                    } else {
                                        selectedItemForDetail = stream
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }

        selectedItemForDetail?.let { item ->
            ItemDetailDialog(
                item = item,
                onDismiss = { selectedItemForDetail = null },
                onPlay = {
                    selectedItemForDetail = null
                    onStreamSelected(item)
                }
            )
        }
    }
}

@Composable
fun LiveChannelCard(item: StreamItem, onClick: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }
    
    val qualityBadge = remember(item.name) {
        val upper = item.name.uppercase()
        when {
            upper.contains("4K") -> "4K"
            upper.contains("FHD") -> "FHD"
            upper.contains("HD") -> "HD"
            upper.contains("SD") -> "SD"
            else -> "LIVE"
        }
    }

    Card(
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .border(
                width = if (isFocused) 3.dp else 1.dp,
                color = if (isFocused) Color(0xFF3B82F6) else Color(0xFF1E293B),
                shape = RoundedCornerShape(10.dp)
            )
            .clickable { onClick() }
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color(0xFF1E293B)),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = item.streamIcon,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(4.dp)
                    )
                }

                Text(
                    text = item.name,
                    color = if (isFocused) Color.White else Color.LightGray,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center
                )

                Text(
                    text = "No EPG data available",
                    color = Color.Gray,
                    fontSize = 10.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center
                )
            }

            // Quality Badge overlay
            Surface(
                color = when (qualityBadge) {
                    "4K" -> Color(0xFFE11D48)
                    "FHD" -> Color(0xFF7C3AED)
                    "HD" -> Color(0xFF2563EB)
                    else -> Color(0xFF475569)
                },
                shape = RoundedCornerShape(bottomStart = 8.dp),
                modifier = Modifier.align(Alignment.TopEnd)
            ) {
                Text(
                    text = qualityBadge,
                    color = Color.White,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
        }
    }
}

@Composable
fun StreamGridItem(item: StreamItem, onClick: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .width(140.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .border(
                width = if (isFocused) 3.dp else 0.dp,
                color = if (isFocused) Color(0xFF3B82F6) else Color.Transparent,
                shape = RoundedCornerShape(8.dp)
            )
            .clickable { onClick() },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Card(
            shape = RoundedCornerShape(8.dp),
            modifier = Modifier
                .aspectRatio(0.7f)
                .fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B))
        ) {
            AsyncImage(
                model = item.streamIcon,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = item.name,
            color = if (isFocused) Color.White else Color.LightGray,
            fontSize = 14.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 4.dp)
        )
    }
}

@Composable
fun ItemDetailDialog(item: StreamItem, onDismiss: () -> Unit, onPlay: () -> Unit) {
    val context = LocalContext.current
    var description by remember { mutableStateOf("Loading details...") }
    var duration by remember { mutableStateOf("") }
    var rating by remember { mutableStateOf("") }

    LaunchedEffect(item.streamId) {
        withContext(Dispatchers.IO) {
            val jsonStr = IptvApiClient.getVodInfo(context, item.streamId)
            try {
                val jsonObj = JSONObject(jsonStr)
                val info = jsonObj.optJSONObject("info")
                description = info?.optString("description") ?: "No description available."
                duration = info?.optString("duration") ?: ""
                rating = info?.optString("rating") ?: ""
            } catch (e: Exception) {
                description = "Could not load details."
            }
        }
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    AsyncImage(
                        model = item.streamIcon,
                        contentDescription = null,
                        modifier = Modifier
                            .width(120.dp)
                            .aspectRatio(0.7f)
                            .clip(RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = item.name,
                            color = Color.White,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold
                        )
                        if (duration.isNotEmpty()) {
                            Text(text = "Duration: $duration", color = Color(0xFF3B82F6), fontSize = 14.sp)
                        }
                        if (rating.isNotEmpty()) {
                            Text(text = "Rating: ⭐ $rating", color = Color.Yellow, fontSize = 14.sp)
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = description,
                            color = Color.LightGray,
                            fontSize = 14.sp,
                            maxLines = 6,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E293B)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Back", color = Color.White)
                    }
                    Button(
                        onClick = onPlay,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF3B82F6)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("▶ Play Now", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
