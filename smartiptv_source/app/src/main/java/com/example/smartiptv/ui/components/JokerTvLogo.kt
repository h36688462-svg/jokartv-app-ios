package com.example.smartiptv.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.smartiptv.ui.theme.SmartIPTVTheme

@Composable
fun JokerTvLogo(
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier.size(200.dp)) {
        val width = size.width
        val height = size.height
        val cx = width / 2f
        val cy = height / 2f

        val tvWidth = width * 0.75f
        val tvHeight = height * 0.65f
        val tvLeft = (width - tvWidth) / 2f
        val tvTop = height * 0.25f

        val tvOuterBrush = Brush.verticalGradient(
            colors = listOf(Color(0xFF6A1B9A), Color(0xFF1565C0), Color(0xFF0D47A1))
        )
        val tvInnerBrush = Brush.radialGradient(
            colors = listOf(Color(0xFF00B0FF), Color(0xFF01579B)),
            center = Offset(cx, tvTop + tvHeight / 2f),
            radius = tvWidth * 0.6f
        )

        drawRoundRect(
            brush = tvOuterBrush,
            topLeft = Offset(tvLeft, tvTop),
            size = Size(tvWidth, tvHeight),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(tvWidth * 0.2f, tvWidth * 0.2f),
            style = Fill
        )

        drawRoundRect(
            brush = tvInnerBrush,
            topLeft = Offset(tvLeft + tvWidth * 0.08f, tvTop + tvHeight * 0.08f),
            size = Size(tvWidth * 0.84f, tvHeight * 0.84f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(tvWidth * 0.15f, tvWidth * 0.15f),
            style = Fill
        )

        val antennaLeftStart = Offset(cx - tvWidth * 0.15f, tvTop)
        val antennaLeftEnd = Offset(cx - tvWidth * 0.35f, tvTop - height * 0.2f)
        drawLine(
            color = Color(0xFF0D1B2A),
            start = antennaLeftStart,
            end = antennaLeftEnd,
            strokeWidth = 6f
        )
        drawCircle(
            color = Color(0xFF0D1B2A),
            radius = 8f,
            center = antennaLeftEnd
        )

        val antennaRightStart = Offset(cx + tvWidth * 0.15f, tvTop)
        val antennaRightEnd = Offset(cx + tvWidth * 0.35f, tvTop - height * 0.25f)
        drawLine(
            color = Color(0xFF0D1B2A),
            start = antennaRightStart,
            end = antennaRightEnd,
            strokeWidth = 6f
        )
        val starPath = Path().apply {
            val starCx = antennaRightEnd.x
            val starCy = antennaRightEnd.y
            val outerR = 12f
            val innerR = 5f
            for (i in 0 until 5) {
                val angleOuter = Math.toRadians((i * 72 - 90).toDouble())
                val angleInner = Math.toRadians((i * 72 + 36 - 90).toDouble())
                val xOut = starCx + outerR * Math.cos(angleOuter).toFloat()
                val yOut = starCy + outerR * Math.sin(angleOuter).toFloat()
                val xIn = starCx + innerR * Math.cos(angleInner).toFloat()
                val yIn = starCy + innerR * Math.sin(angleInner).toFloat()
                if (i == 0) moveTo(xOut, yOut) else lineTo(xOut, yOut)
                lineTo(xIn, yIn)
            }
            close()
        }
        drawPath(starPath, Color(0xFF0D1B2A))

        val hatLeftPath = Path().apply {
            moveTo(cx, cy - height * 0.15f)
            cubicTo(cx - width * 0.15f, cy - height * 0.3f, cx - width * 0.35f, cy - height * 0.2f, cx - width * 0.28f, cy - height * 0.05f)
            cubicTo(cx - width * 0.25f, cy, cx - width * 0.18f, cy - height * 0.05f, cx - width * 0.15f, cy - height * 0.12f)
            close()
        }
        drawPath(
            brush = Brush.verticalGradient(listOf(Color(0xFF8E24AA), Color(0xFF4A148C))),
            path = hatLeftPath
        )
        drawCircle(color = Color(0xFFFFD54F), radius = 10f, center = Offset(cx - width * 0.28f, cy - height * 0.02f))
        drawCircle(color = Color(0xFFB71C1C), radius = 4f, center = Offset(cx - width * 0.28f, cy - height * 0.02f))

        val hatCenterPath = Path().apply {
            moveTo(cx, cy - height * 0.18f)
            cubicTo(cx - width * 0.1f, cy - height * 0.45f, cx + width * 0.15f, cy - height * 0.45f, cx + width * 0.05f, cy - height * 0.15f)
            cubicTo(cx + width * 0.02f, cy - height * 0.08f, cx - width * 0.02f, cy - height * 0.08f, cx, cy - height * 0.18f)
            close()
        }
        drawPath(
            brush = Brush.verticalGradient(listOf(Color(0xFF00E676), Color(0xFF1B5E20))),
            path = hatCenterPath
        )
        drawCircle(color = Color(0xFFFFD54F), radius = 10f, center = Offset(cx + width * 0.12f, cy - height * 0.35f))
        drawCircle(color = Color(0xFFB71C1C), radius = 4f, center = Offset(cx + width * 0.12f, cy - height * 0.35f))

        val hatRightPath = Path().apply {
            moveTo(cx + width * 0.05f, cy - height * 0.18f)
            cubicTo(cx + width * 0.2f, cy - height * 0.35f, cx + width * 0.38f, cy - height * 0.25f, cx + width * 0.32f, cy - height * 0.08f)
            cubicTo(cx + width * 0.28f, cy - height * 0.02f, cx + width * 0.15f, cy - height * 0.08f, cx + width * 0.1f, cy - height * 0.15f)
            close()
        }
        drawPath(
            brush = Brush.verticalGradient(listOf(Color(0xFFFFEA00), Color(0xFFFF6F00))),
            path = hatRightPath
        )
        drawCircle(color = Color(0xFFFFD54F), radius = 10f, center = Offset(cx + width * 0.32f, cy - height * 0.06f))
        drawCircle(color = Color(0xFFB71C1C), radius = 4f, center = Offset(cx + width * 0.32f, cy - height * 0.06f))

        val maskPath = Path().apply {
            moveTo(cx, cy - height * 0.05f)
            cubicTo(cx - width * 0.18f, cy - height * 0.05f, cx - width * 0.25f, cy + height * 0.15f, cx - width * 0.18f, cy + height * 0.28f)
            cubicTo(cx - width * 0.12f, cy + height * 0.38f, cx - width * 0.05f, cy + height * 0.42f, cx, cy + height * 0.44f)
            cubicTo(cx + width * 0.05f, cy + height * 0.42f, cx + width * 0.12f, cy + height * 0.38f, cx + width * 0.18f, cy + height * 0.28f)
            cubicTo(cx + width * 0.25f, cy + height * 0.15f, cx + width * 0.18f, cy - height * 0.05f, cx, cy - height * 0.05f)
            close()
        }
        drawPath(color = Color(0xFFECEFF1), path = maskPath)
        drawPath(color = Color(0xFF0D1B2A), path = maskPath, style = Stroke(width = 3f))

        val eyeLeftPath = Path().apply {
            moveTo(cx - width * 0.12f, cy + height * 0.08f)
            cubicTo(cx - width * 0.08f, cy + height * 0.02f, cx - width * 0.03f, cy + height * 0.08f, cx - width * 0.05f, cy + height * 0.18f)
            cubicTo(cx - width * 0.08f, cy + height * 0.22f, cx - width * 0.12f, cy + height * 0.15f, cx - width * 0.12f, cy + height * 0.08f)
            close()
        }
        drawPath(color = Color(0xFF0D1B2A), path = eyeLeftPath)

        val eyeRightPath = Path().apply {
            moveTo(cx + width * 0.12f, cy + height * 0.08f)
            cubicTo(cx + width * 0.08f, cy + height * 0.02f, cx + width * 0.03f, cy + height * 0.08f, cx + width * 0.05f, cy + height * 0.18f)
            cubicTo(cx + width * 0.08f, cy + height * 0.22f, cx + width * 0.12f, cy + height * 0.15f, cx + width * 0.12f, cy + height * 0.08f)
            close()
        }
        drawPath(color = Color(0xFF0D1B2A), path = eyeRightPath)

        val diamondLeft = Path().apply {
            moveTo(cx - width * 0.09f, cy + height * 0.02f)
            lineTo(cx - width * 0.06f, cy + height * 0.07f)
            lineTo(cx - width * 0.09f, cy + height * 0.12f)
            lineTo(cx - width * 0.12f, cy + height * 0.07f)
            close()
        }
        drawPath(color = Color(0xFF00B0FF), path = diamondLeft)

        val diamondRight = Path().apply {
            moveTo(cx + width * 0.09f, cy + height * 0.02f)
            lineTo(cx + width * 0.06f, cy + height * 0.07f)
            lineTo(cx + width * 0.09f, cy + height * 0.12f)
            lineTo(cx + width * 0.12f, cy + height * 0.07f)
            close()
        }
        drawPath(color = Color(0xFF00B0FF), path = diamondRight)

        val nosePath = Path().apply {
            moveTo(cx, cy + height * 0.16f)
            lineTo(cx - width * 0.025f, cy + height * 0.24f)
            lineTo(cx + width * 0.025f, cy + height * 0.24f)
            close()
        }
        drawPath(color = Color(0xFF0D1B2A), path = nosePath)

        val mouthPath = Path().apply {
            moveTo(cx - width * 0.12f, cy + height * 0.28f)
            quadraticBezierTo(cx, cy + height * 0.42f, cx + width * 0.15f, cy + height * 0.30f)
            quadraticBezierTo(cx + width * 0.18f, cy + height * 0.35f, cx + width * 0.12f, cy + height * 0.36f)
            quadraticBezierTo(cx, cy + height * 0.46f, cx - width * 0.10f, cy + height * 0.32f)
            close()
        }
        drawPath(color = Color(0xFFD32F2F), path = mouthPath)

        val chinSwirlPath = Path().apply {
            moveTo(cx, cy + height * 0.39f)
            cubicTo(cx + width * 0.04f, cy + height * 0.39f, cx + width * 0.05f, cy + height * 0.43f, cx, cy + height * 0.43f)
            cubicTo(cx - width * 0.03f, cy + height * 0.43f, cx - width * 0.02f, cy + height * 0.40f, cx, cy + height * 0.40f)
        }
        drawPath(color = Color(0xFFD32F2F), path = chinSwirlPath, style = Stroke(width = 3f))
    }
}

@Preview(showBackground = true, backgroundColor = 0xFFF0F0F0)
@Composable
fun JokerTvLogoPreview() {
    SmartIPTVTheme {
        Box(
            modifier = Modifier.size(300.dp),
            contentAlignment = Alignment.Center
        ) {
            JokerTvLogo()
        }
    }
}
