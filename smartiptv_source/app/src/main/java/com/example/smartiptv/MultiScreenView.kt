package com.example.smartiptv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

@Composable
fun MultiScreenView(
    streamId1: String,
    streamType1: String,
    streamId2: String,
    streamType2: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current

    val player1 = remember {
        ExoPlayer.Builder(context).build().apply {
            val url = IptvApiClient.getStreamUrl(context, streamType1, streamId1)
            setMediaItem(MediaItem.fromUri(url.toUri()))
            prepare()
            playWhenReady = true
        }
    }

    val player2 = remember {
        ExoPlayer.Builder(context).build().apply {
            val url = IptvApiClient.getStreamUrl(context, streamType2, streamId2)
            setMediaItem(MediaItem.fromUri(url.toUri()))
            prepare()
            playWhenReady = true
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            player1.release()
            player2.release()
        }
    }

    Column(modifier = Modifier.fillMaxSize().background(Color.Black)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        ) {
            Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                AndroidView(
                    factory = { PlayerView(it).apply { player = player1 } },
                    modifier = Modifier.fillMaxSize()
                )
            }
            Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                AndroidView(
                    factory = { PlayerView(it).apply { player = player2 } },
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
        Button(
            onClick = {
                player1.release()
                player2.release()
                onBack()
            },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE50914)),
            modifier = Modifier.align(Alignment.CenterHorizontally).padding(8.dp)
        ) {
            Text("إغلاق الشاشات المتعددة", color = Color.White)
        }
    }
}