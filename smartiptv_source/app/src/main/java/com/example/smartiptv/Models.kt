package com.example.smartiptv

data class StreamItem(
    val streamId: String,
    val name: String,
    val streamIcon: String?,
    val streamType: String // "live", "movies", or "series"
)

data class DashboardCategory(
    val categoryId: String,
    val categoryName: String,
    val items: List<StreamItem>
)

data class SeriesDetails(
    val cover: String,
    val plot: String,
    val seasonsMap: Map<String, List<EpisodeItem>>,
    val seasonList: List<String>
)

data class EpisodeItem(
    val id: String,
    val episodeNum: String,
    val title: String,
    val containerExtension: String,
    val cover: String
)

data class VodDetails(
    val name: String,
    val description: String,
    val duration: String,
    val rating: String,
    val director: String,
    val actors: String,
    val genre: String,
    val releaseDate: String,
    val cover: String
)
