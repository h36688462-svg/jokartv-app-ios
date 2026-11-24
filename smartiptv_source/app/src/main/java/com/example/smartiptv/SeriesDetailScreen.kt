package com.example.smartiptv

import androidx.activity.compose.BackHandler
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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage

@Composable
fun SeriesDetailScreen(
    seriesId: String,
    seriesName: String,
    onEpisodeSelected: (StreamItem) -> Unit,
    onBack: () -> Unit,
    viewModel: SeriesViewModel = viewModel()
) {
    val context = LocalContext.current
    val details = viewModel.details.value
    val isLoading = viewModel.isLoading.value
    val selectedSeason = viewModel.selectedSeason.value

    BackHandler {
        onBack()
    }

    LaunchedEffect(seriesId) {
        viewModel.loadSeriesInfo(context, seriesId)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0B0B0B))
    ) {
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Color(0xFFE50914))
            }
        } else if (details != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    AsyncImage(
                        model = details.cover,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .width(120.dp)
                            .height(180.dp)
                            .clip(RoundedCornerShape(8.dp))
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconButton(onClick = onBack) {
                                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(text = seriesName, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(text = details.plot, color = Color.LightGray, fontSize = 13.sp, maxLines = 5)
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Text(text = stringResource(R.string.seasons), color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(details.seasonList) { season ->
                        val isSelected = season == selectedSeason
                        var isSeasonFocused by remember { mutableStateOf(false) }
                        Box(
                            modifier = Modifier
                                .onFocusChanged { isSeasonFocused = it.isFocused }
                                .focusable()
                                .border(if (isSeasonFocused || isSelected) 2.dp else 0.dp, Color.Yellow, RoundedCornerShape(8.dp))
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (isSelected) Color(0xFFE50914) else Color(0xFF1F1F1F))
                                .clickable { viewModel.selectSeason(season) }
                                .padding(horizontal = 16.dp, vertical = 10.dp)
                        ) {
                            Text(text = "Season $season", color = Color.White, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Text(text = stringResource(R.string.episodes), color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))

                val currentEpisodes = details.seasonsMap[selectedSeason] ?: emptyList()
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(currentEpisodes) { ep ->
                        var isEpFocused by remember { mutableStateOf(false) }
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .onFocusChanged { isEpFocused = it.isFocused }
                                .focusable()
                                .border(if (isEpFocused) 2.dp else 0.dp, Color.Yellow, RoundedCornerShape(8.dp))
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFF1F1F1F))
                                .clickable {
                                    onEpisodeSelected(StreamItem(ep.id, ep.title, ep.cover, "series"))
                                }
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Ep ${ep.episodeNum}",
                                color = Color(0xFFE50914),
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                modifier = Modifier.width(90.dp)
                            )
                            Text(
                                text = ep.title,
                                color = Color.White,
                                fontSize = 14.sp,
                                modifier = Modifier.weight(1f)
                            )
                            Text(text = "▶ " + stringResource(R.string.play), color = Color.LightGray, fontSize = 13.sp)
                        }
                    }
                }
            }
        }
    }
}
