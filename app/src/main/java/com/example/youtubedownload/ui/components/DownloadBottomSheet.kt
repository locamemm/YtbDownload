package com.example.youtubedownload.ui.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Audiotrack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.rounded.FolderOpen
import androidx.compose.material.icons.rounded.HighQuality
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.Movie
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.youtubedownload.data.download.AndroidDownloadManagerHelper
import com.example.youtubedownload.data.model.ConversionUiState
import com.example.youtubedownload.data.model.MediaFormat
import com.example.youtubedownload.data.model.VideoItem
import com.example.youtubedownload.ui.theme.BlueAccent
import com.example.youtubedownload.ui.theme.CyanAccent
import com.example.youtubedownload.ui.theme.DarkBackground
import com.example.youtubedownload.ui.theme.DarkSurfaceCard
import com.example.youtubedownload.ui.theme.DarkSurfaceElevated
import com.example.youtubedownload.ui.theme.DarkSurfaceGlass
import com.example.youtubedownload.ui.theme.GlassBorder
import com.example.youtubedownload.ui.theme.GlassBorderGradient
import com.example.youtubedownload.ui.theme.MintAccent
import com.example.youtubedownload.ui.theme.PrimaryGradient
import com.example.youtubedownload.ui.theme.TextMuted
import com.example.youtubedownload.ui.theme.TextPrimary
import com.example.youtubedownload.ui.theme.TextSecondary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DownloadBottomSheet(
    video: VideoItem,
    conversionState: ConversionUiState,
    onDismiss: () -> Unit,
    onSelectFormat: (MediaFormat) -> Unit,
    onCopyCleanUrl: (VideoItem) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Video", "Audio", "Utilities")
    val context = LocalContext.current

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = DarkBackground,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 12.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(CircleShape)
                    .background(GlassBorder)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .navigationBarsPadding()
        ) {
            // Header: Title and Close button
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Grab Media",
                        color = CyanAccent,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = video.title,
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = "${video.author} • ${video.formattedDuration}",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(DarkSurfaceElevated)
                        .size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Close,
                        contentDescription = "Close",
                        tint = TextSecondary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Conversion Progress / Status overlay if active
            if (conversionState !is ConversionUiState.Idle) {
                ConversionProgressView(
                    state = conversionState,
                    onViewDownloads = { AndroidDownloadManagerHelper.openDownloadsFolder(context) },
                    onRetry = { onSelectFormat(MediaFormat.VIDEO_720) }
                )
                Spacer(modifier = Modifier.height(20.dp))
            }

            // Tab Row
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.Transparent,
                contentColor = CyanAccent,
                indicator = { tabPositions ->
                    TabRowDefaults.SecondaryIndicator(
                        modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                        color = CyanAccent,
                        height = 2.5.dp
                    )
                },
                divider = {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(1.dp)
                            .background(GlassBorder)
                    )
                }
            ) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Text(
                                text = title,
                                fontSize = 14.sp,
                                fontWeight = if (selectedTab == index) FontWeight.Bold else FontWeight.Medium,
                                color = if (selectedTab == index) CyanAccent else TextSecondary
                            )
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Tab Content
            AnimatedContent(
                targetState = selectedTab,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "TabContent"
            ) { tabIndex ->
                when (tabIndex) {
                    0 -> VideoOptionsList(onSelectFormat = onSelectFormat)
                    1 -> AudioOptionsList(onSelectFormat = onSelectFormat)
                    2 -> UtilitiesOptionsList(
                        onDownloadThumbnail = { onSelectFormat(MediaFormat.THUMBNAIL_HD) },
                        onCopyCleanUrl = { onCopyCleanUrl(video) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun VideoOptionsList(
    onSelectFormat: (MediaFormat) -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        OptionChip(
            icon = Icons.Rounded.HighQuality,
            title = MediaFormat.VIDEO_1080.label,
            subtitle = MediaFormat.VIDEO_1080.subLabel,
            badge = "BEST",
            badgeColor = CyanAccent,
            onClick = { onSelectFormat(MediaFormat.VIDEO_1080) }
        )
        OptionChip(
            icon = Icons.Rounded.Movie,
            title = MediaFormat.VIDEO_720.label,
            subtitle = MediaFormat.VIDEO_720.subLabel,
            badge = "RECOMMENDED",
            badgeColor = BlueAccent,
            onClick = { onSelectFormat(MediaFormat.VIDEO_720) }
        )
        OptionChip(
            icon = Icons.Rounded.Videocam,
            title = MediaFormat.VIDEO_480.label,
            subtitle = MediaFormat.VIDEO_480.subLabel,
            badge = "DATA SAVER",
            badgeColor = TextMuted,
            onClick = { onSelectFormat(MediaFormat.VIDEO_480) }
        )
        OptionChip(
            icon = Icons.Rounded.Videocam,
            title = MediaFormat.VIDEO_360.label,
            subtitle = MediaFormat.VIDEO_360.subLabel,
            badge = "FAST",
            badgeColor = TextMuted,
            onClick = { onSelectFormat(MediaFormat.VIDEO_360) }
        )
    }
}

@Composable
private fun AudioOptionsList(
    onSelectFormat: (MediaFormat) -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        OptionChip(
            icon = Icons.Rounded.Audiotrack,
            title = MediaFormat.AUDIO_MP3.label,
            subtitle = MediaFormat.AUDIO_MP3.subLabel,
            badge = "320 KBPS",
            badgeColor = MintAccent,
            onClick = { onSelectFormat(MediaFormat.AUDIO_MP3) }
        )
        OptionChip(
            icon = Icons.Rounded.Audiotrack,
            title = MediaFormat.AUDIO_M4A.label,
            subtitle = MediaFormat.AUDIO_M4A.subLabel,
            badge = "APPLE AAC",
            badgeColor = BlueAccent,
            onClick = { onSelectFormat(MediaFormat.AUDIO_M4A) }
        )
        OptionChip(
            icon = Icons.Rounded.Audiotrack,
            title = MediaFormat.AUDIO_WAV.label,
            subtitle = MediaFormat.AUDIO_WAV.subLabel,
            badge = "LOSSLESS",
            badgeColor = CyanAccent,
            onClick = { onSelectFormat(MediaFormat.AUDIO_WAV) }
        )
    }
}

@Composable
private fun UtilitiesOptionsList(
    onDownloadThumbnail: () -> Unit,
    onCopyCleanUrl: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        OptionChip(
            icon = Icons.Rounded.Image,
            title = "Download HD Thumbnail",
            subtitle = "Direct 1080p MaxRes JPG Cover",
            badge = "HD COVER",
            badgeColor = CyanAccent,
            onClick = onDownloadThumbnail
        )
        OptionChip(
            icon = Icons.Rounded.ContentCopy,
            title = "Copy Clean URL",
            subtitle = "Direct clean link without tracking params",
            badge = "CLIPBOARD",
            badgeColor = BlueAccent,
            onClick = onCopyCleanUrl
        )
    }
}

@Composable
private fun OptionChip(
    icon: ImageVector,
    title: String,
    subtitle: String,
    badge: String,
    badgeColor: Color,
    onClick: () -> Unit
) {
    GlassmorphicCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(DarkSurfaceElevated),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = CyanAccent,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(14.dp))

                Column {
                    Text(
                        text = title,
                        color = TextPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                }
            }

            // Quality Pill Badge
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(DarkSurfaceElevated)
                    .border(0.8.dp, badgeColor.copy(alpha = 0.5f), RoundedCornerShape(6.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    text = badge,
                    color = badgeColor,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun ConversionProgressView(
    state: ConversionUiState,
    onViewDownloads: () -> Unit,
    onRetry: () -> Unit
) {
    GlassmorphicCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            when (state) {
                is ConversionUiState.Analyzing -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        CircularProgressIndicator(
                            color = CyanAccent,
                            strokeWidth = 2.5.dp,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = state.message,
                            color = CyanAccent,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                is ConversionUiState.Converting -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = state.statusText,
                            color = TextPrimary,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "${state.progressPercent}%",
                            color = CyanAccent,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                    LinearProgressIndicator(
                        progress = { state.progressPercent / 100f },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp)),
                        color = CyanAccent,
                        trackColor = DarkSurfaceElevated
                    )
                }

                is ConversionUiState.Enqueueing -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        CircularProgressIndicator(
                            color = MintAccent,
                            strokeWidth = 2.5.dp,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = state.message,
                            color = MintAccent,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                is ConversionUiState.Success -> {
                    Icon(
                        imageVector = Icons.Rounded.CheckCircle,
                        contentDescription = "Success",
                        tint = MintAccent,
                        modifier = Modifier.size(36.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Enqueued to DownloadManager!",
                        color = MintAccent,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = state.fileName,
                        color = TextSecondary,
                        fontSize = 12.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(
                        onClick = onViewDownloads,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = DarkSurfaceElevated,
                            contentColor = CyanAccent
                        ),
                        shape = RoundedCornerShape(10.dp),
                        border = BorderStroke(1.dp, GlassBorder)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.FolderOpen,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "View in Downloads", fontSize = 13.sp)
                    }
                }

                is ConversionUiState.Error -> {
                    Icon(
                        imageVector = Icons.Rounded.ErrorOutline,
                        contentDescription = "Error",
                        tint = Color(0xFFFF5E62),
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = state.message,
                        color = Color(0xFFFF5E62),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Button(
                        onClick = onRetry,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = DarkSurfaceElevated,
                            contentColor = TextPrimary
                        ),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Refresh,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Try Again", fontSize = 13.sp)
                    }
                }

                ConversionUiState.Idle -> Unit
            }
        }
    }
}
