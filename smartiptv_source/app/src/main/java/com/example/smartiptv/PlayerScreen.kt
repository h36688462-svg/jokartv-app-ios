package com.example.smartiptv

import android.content.ComponentName
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import androidx.media3.ui.PlayerView
import com.google.common.util.concurrent.MoreExecutors
import kotlinx.coroutines.delay

@OptIn(UnstableApi::class)
@Composable
fun PlayerScreen(
    streamId: String,
    streamType: String,
    streamName: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    var isFavorite by remember { mutableStateOf(WatchHistoryManager.isFavorite(context, streamId)) }
    var showControls by remember { mutableStateOf(true) }
    var isPlaying by remember { mutableStateOf(false) }
    var playbackPosition by remember { mutableLongStateOf(0L) }
    var totalDuration by remember { mutableLongStateOf(0L) }
    var showTrackSettings by remember { mutableStateOf(false) }

    var controller by remember { mutableStateOf<MediaController?>(null) }

    DisposableEffect(Unit) {
        val sessionToken = SessionToken(context, ComponentName(context, PlaybackService::class.java))
        val controllerFuture = MediaController.Builder(context, sessionToken).buildAsync()
        
        controllerFuture.addListener({
            try {
                val mediaController = controllerFuture.get()
                controller = mediaController
                
                if (mediaController.currentMediaItem?.mediaId != streamId) {
                    val url = IptvApiClient.getStreamUrl(context, streamType, streamId)
                    val mediaMetadata = MediaMetadata.Builder()
                        .setTitle(streamName)
                        .setDisplayTitle(streamName)
                        .build()
                    
                    val mediaItem = MediaItem.Builder()
                        .setUri(url.toUri())
                        .setMediaMetadata(mediaMetadata)
                        .setMediaId(streamId)
                        .build()

                    mediaController.setMediaItem(mediaItem)
                    
                    val savedProgress = WatchHistoryManager.getProgress(context, streamId)
                    if (savedProgress > 0 && streamType != "live") {
                        mediaController.seekTo(savedProgress)
                    }
                    
                    mediaController.prepare()
                    mediaController.play()
                }
                isPlaying = mediaController.isPlaying
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }, MoreExecutors.directExecutor())

        onDispose {
            controller?.let {
                if (streamType != "live") {
                    WatchHistoryManager.saveProgress(context, streamId, it.currentPosition, it.duration)
                }
                MediaController.releaseFuture(controllerFuture)
            }
        }
    }

    LaunchedEffect(controller) {
        controller?.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(playing: Boolean) {
                isPlaying = playing
            }
        })
    }

    LaunchedEffect(showControls, isPlaying) {
        if (showControls && isPlaying) {
            delay(5000)
            showControls = false
        }
    }

    LaunchedEffect(Unit) {
        while (true) {
            controller?.let {
                playbackPosition = it.currentPosition
                totalDuration = it.duration
            }
            delay(1000)
        }
    }

    BackHandler {
        onBack()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) { showControls = !showControls }
    ) {
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = controller
                    useController = false 
                }
            },
            update = { playerView ->
                playerView.player = controller
            },
            modifier = Modifier.fillMaxSize()
        )

        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f))
            ) {
                // Top Bar
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 20.dp)
                        .align(Alignment.TopStart),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = { onBack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White, modifier = Modifier.size(32.dp))
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(
                        text = streamName,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                // Netflix Style Center Controls
                Row(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalArrangement = Arrangement.spacedBy(64.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = { controller?.seekBack() }) {
                        Icon(Icons.Default.Replay10, contentDescription = "Back 10s", tint = Color.White, modifier = Modifier.size(56.dp))
                    }

                    IconButton(
                        onClick = { 
                            controller?.let {
                                if (it.isPlaying) it.pause() else it.play()
                            }
                        },
                        modifier = Modifier
                            .size(100.dp)
                            .background(Color.White.copy(alpha = 0.1f), CircleShape)
                    ) {
                        Icon(
                            imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = "Play/Pause",
                            tint = Color.White,
                            modifier = Modifier.size(64.dp)
                        )
                    }

                    IconButton(onClick = { controller?.seekForward() }) {
                        Icon(Icons.Default.Forward10, contentDescription = "Forward 10s", tint = Color.White, modifier = Modifier.size(56.dp))
                    }
                }

                // Bottom Control Bar
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 32.dp, vertical = 32.dp)
                        .align(Alignment.BottomCenter)
                ) {
                    if (streamType != "live") {
                        Slider(
                            value = if (totalDuration > 0) (playbackPosition.toFloat() / totalDuration).coerceIn(0f, 1f) else 0f,
                            onValueChange = { controller?.seekTo((it * totalDuration).toLong()) },
                            colors = SliderDefaults.colors(
                                thumbColor = Color.Red,
                                activeTrackColor = Color.Red,
                                inactiveTrackColor = Color.White.copy(alpha = 0.3f)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(formatTime(playbackPosition), color = Color.White, fontSize = 14.sp)
                            Text(formatTime(totalDuration), color = Color.White, fontSize = 14.sp)
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth().padding(top = 16.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        TextButton(onClick = { showTrackSettings = true }) {
                            Icon(Icons.Default.Settings, contentDescription = null, tint = Color.White)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Audio & Subtitles", color = Color.White, fontWeight = FontWeight.Bold)
                        }
                        
                        Spacer(modifier = Modifier.width(48.dp))

                        IconButton(onClick = { WatchHistoryManager.toggleFavorite(context, streamId); isFavorite = !isFavorite }) {
                            Icon(imageVector = if (isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder, contentDescription = "Favorite", tint = if (isFavorite) Color.Red else Color.White)
                        }
                    }
                }
            }
        }

        if (showTrackSettings && controller != null) {
            TrackSelectionDialog(controller = controller!!, onDismiss = { showTrackSettings = false })
        }
    }
}

@OptIn(UnstableApi::class)
@Composable
fun TrackSelectionDialog(controller: MediaController, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Color(0xFF1F1F1F),
        title = { Text("Playback Options", color = Color.White) },
        text = {
            val tracks = controller.currentTracks
            LazyColumn(modifier = Modifier.height(300.dp)) {
                item { Text("Audio", color = Color.Red, fontWeight = FontWeight.Bold, modifier = Modifier.padding(vertical = 8.dp)) }
                val audioGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }
                items(audioGroups) { group ->
                    for (i in 0 until group.length) {
                        if (group.isTrackSupported(i)) {
                            val format = group.getTrackFormat(i)
                            Text(
                                text = format.language?.uppercase() ?: "Default Audio",
                                color = if (group.isTrackSelected(i)) Color.Red else Color.White,
                                modifier = Modifier.fillMaxWidth().clickable {
                                    controller.trackSelectionParameters = controller.trackSelectionParameters.buildUpon()
                                        .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, i)).build()
                                    onDismiss()
                                }.padding(12.dp)
                            )
                        }
                    }
                }
                item { Text("Subtitles", color = Color.Red, fontWeight = FontWeight.Bold, modifier = Modifier.padding(vertical = 8.dp)) }
                val textGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
                item {
                    Text(text = "Off", color = if (textGroups.none { it.isSelected }) Color.Red else Color.White,
                        modifier = Modifier.fillMaxWidth().clickable {
                            controller.trackSelectionParameters = controller.trackSelectionParameters.buildUpon()
                                .setDisabledTrackTypes(setOf(C.TRACK_TYPE_TEXT)).build()
                            onDismiss()
                        }.padding(12.dp))
                }
                items(textGroups) { group ->
                    for (i in 0 until group.length) {
                        if (group.isTrackSupported(i)) {
                            val format = group.getTrackFormat(i)
                            Text(
                                text = format.language?.uppercase() ?: "Subtitle ${i+1}",
                                color = if (group.isTrackSelected(i)) Color.Red else Color.White,
                                modifier = Modifier.fillMaxWidth().clickable {
                                    controller.trackSelectionParameters = controller.trackSelectionParameters.buildUpon()
                                        .setDisabledTrackTypes(emptySet()).setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, i)).build()
                                    onDismiss()
                                }.padding(12.dp)
                            )
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Close", color = Color.White) } }
    )
}

private fun formatTime(ms: Long): String {
    if (ms <= 0) return "00:00"
    val totalSeconds = ms / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) String.format("%02d:%02d:%02d", hours, minutes, seconds)
    else String.format("%02d:%02d", minutes, seconds)
}
