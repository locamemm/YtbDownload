package com.example.youtubedownload.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// Glassmorphism Dark Theme Core Palette
val DarkBackground = Color(0xFF080C14)
val DarkSurface = Color(0xFF0F172A)
val DarkSurfaceGlass = Color(0xCC162032) // 80% opacity dark slate
val DarkSurfaceCard = Color(0xE6131D2E)
val DarkSurfaceElevated = Color(0xFF1E293B)

// Vibrant Accents (Cyan / Teal)
val CyanAccent = Color(0xFF00F2FE)
val BlueAccent = Color(0xFF4FACFE)
val TealAccent = Color(0xFF00E5FF)
val MintAccent = Color(0xFF10B981)
val CoralAccent = Color(0xFFFF5E62)

// Glass Borders & Outlines
val GlassBorder = Color(0x3300F2FE) // 20% cyan outline
val GlassBorderSubtle = Color(0x1A4FACFE) // 10% blue outline
val GlassBorderHover = Color(0x6600F2FE)

// Typography Colors
val TextPrimary = Color(0xFFF8FAFC)
val TextSecondary = Color(0xFF94A3B8)
val TextMuted = Color(0xFF64748B)

// Pre-defined Brushes
val PrimaryGradient = Brush.horizontalGradient(
    colors = listOf(CyanAccent, BlueAccent)
)

val GlassBorderGradient = Brush.linearGradient(
    colors = listOf(
        Color(0x6600F2FE),
        Color(0x224FACFE),
        Color(0x1100F2FE)
    )
)

val CardBackgroundGradient = Brush.verticalGradient(
    colors = listOf(
        Color(0xCC162235),
        Color(0xCC0E1724)
    )
)