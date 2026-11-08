class StreamItem {
  final String streamId;
  final String name;
  final String? streamIcon;
  final String streamType; // "live", "movies", or "series"
  final String? categoryId;
  final String? rating;
  final String? containerExtension;
  final String? plot;
  final String? genre;
  final String? cast;
  final String? releaseDate;
  final String? director;
  final String? duration;

  StreamItem({
    required this.streamId,
    required this.name,
    this.streamIcon,
    required this.streamType,
    this.categoryId,
    this.rating,
    this.containerExtension,
    this.plot,
    this.genre,
    this.cast,
    this.releaseDate,
    this.director,
    this.duration,
  });

  factory StreamItem.fromJson(Map<String, dynamic> json, String type) {
    final id = (json['stream_id'] ?? json['series_id'] ?? json['id'] ?? '').toString();
    final title = (json['name'] ?? json['title'] ?? 'Unknown').toString();
    final icon = (json['stream_icon'] ?? json['cover'])?.toString();
    final catId = (json['category_id'] ?? '').toString();
    final extension = json['container_extension']?.toString();
    final plot = (json['plot'] ?? json['description'] ?? json['overview'] ?? json['summary'])?.toString();
    final genre = (json['genre'] ?? json['category_name'])?.toString();
    final cast = (json['cast'] ?? json['actors'])?.toString();
    final releaseDate = (json['releasedate'] ?? json['release_date'])?.toString();
    final director = (json['director'] ?? json['directors'])?.toString();
    final duration = (json['duration'] ?? json['duration_secs'])?.toString();

    return StreamItem(
      streamId: id,
      name: title,
      streamIcon: (icon != null && icon.isNotEmpty) ? icon : null,
      streamType: type,
      categoryId: catId,
      rating: json['rating']?.toString(),
      containerExtension: extension,
      plot: plot,
      genre: genre,
      cast: cast,
      releaseDate: releaseDate,
      director: director,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stream_id': streamId,
      'name': name,
      'stream_icon': streamIcon,
      'stream_type': streamType,
      'category_id': categoryId,
      'rating': rating,
      'container_extension': containerExtension,
    };
  }
}

class CategoryItem {
  final String categoryId;
  final String categoryName;
  final String? parentId;

  CategoryItem({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      categoryId: (json['category_id'] ?? '').toString(),
      categoryName: (json['category_name'] ?? json['name'] ?? 'Uncategorized').toString(),
      parentId: json['parent_id']?.toString(),
    );
  }
}

class DashboardCategory {
  final String categoryId;
  final String categoryName;
  final List<StreamItem> items;

  DashboardCategory({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });
}

class SeriesDetails {
  final String cover;
  final String plot;
  final Map<String, List<EpisodeItem>> seasonsMap;
  final List<String> seasonList;
  final String? genre;
  final String? releaseDate;
  final String? rating;
  final String? director;
  final String? actors;

  SeriesDetails({
    required this.cover,
    required this.plot,
    required this.seasonsMap,
    required this.seasonList,
    this.genre,
    this.releaseDate,
    this.rating,
    this.director,
    this.actors,
  });

  factory SeriesDetails.fromJson(Map<String, dynamic> json) {
    final info = (json['info'] is Map<String, dynamic>) ? json['info'] as Map<String, dynamic> : <String, dynamic>{};
    final episodesObj = json['episodes'];

    final coverImg = (info['cover'] ?? info['poster'] ?? '').toString();
    final rawPlot = (info['plot'] ?? info['description'] ?? info['overview'] ?? info['summary'] ?? '').toString();
    final plotText = rawPlot.isNotEmpty
        ? rawPlot
        : 'قصة المسلسل: استمتع بمشاهدة أحدث المسلسلات والحلقات الحصرية بجودة عالية وبدون تقطيع عبر منصة Jokar TV.';

    final seasonsMap = <String, List<EpisodeItem>>{};
    final seasonList = <String>[];

    if (episodesObj is Map<String, dynamic>) {
      episodesObj.forEach((seasonNum, epList) {
        seasonList.add(seasonNum);
        final episodes = <EpisodeItem>[];
        if (epList is List) {
          for (var item in epList) {
            if (item is Map<String, dynamic>) {
              episodes.add(EpisodeItem.fromJson(item, seasonNum));
            }
          }
        }
        seasonsMap[seasonNum] = episodes;
      });
    }

    return SeriesDetails(
      cover: coverImg,
      plot: plotText,
      seasonsMap: seasonsMap,
      seasonList: seasonList,
      genre: (info['genre'] ?? info['category_name'])?.toString(),
      releaseDate: (info['releaseDate'] ?? info['releasedate'] ?? info['release_date'])?.toString(),
      rating: info['rating']?.toString(),
      director: (info['director'] ?? info['directors'])?.toString(),
      actors: (info['actors'] ?? info['cast'])?.toString(),
    );
  }
}

class EpisodeItem {
  final String id;
  final String episodeNum;
  final String title;
  final String containerExtension;
  final String cover;
  final String season;

  EpisodeItem({
    required this.id,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    required this.cover,
    required this.season,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json, String season) {
    final info = (json['info'] is Map<String, dynamic>) ? json['info'] as Map<String, dynamic> : <String, dynamic>{};
    return EpisodeItem(
      id: (json['id'] ?? json['stream_id'] ?? '').toString(),
      episodeNum: (json['episode_num'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Episode').toString(),
      containerExtension: (json['container_extension'] ?? 'mp4').toString(),
      cover: (info['movie_image'] ?? json['cover'] ?? '').toString(),
      season: season,
    );
  }
}

class VodDetails {
  final String name;
  final String description;
  final String duration;
  final String rating;
  final String director;
  final String actors;
  final String genre;
  final String releaseDate;
  final String cover;
  final String containerExtension;

  VodDetails({
    required this.name,
    required this.description,
    required this.duration,
    required this.rating,
    required this.director,
    required this.actors,
    required this.genre,
    required this.releaseDate,
    required this.cover,
    required this.containerExtension,
  });

  factory VodDetails.fromJson(Map<String, dynamic> json) {
    final info = (json['info'] is Map<String, dynamic>) ? json['info'] as Map<String, dynamic> : <String, dynamic>{};
    final movieData = (json['movie_data'] is Map<String, dynamic>) ? json['movie_data'] as Map<String, dynamic> : <String, dynamic>{};

    final rawDesc = (info['description'] ?? info['plot'] ?? info['overview'] ?? info['summary'] ?? json['plot'] ?? json['description'] ?? movieData['plot'] ?? movieData['description'] ?? '').toString();
    final desc = rawDesc.isNotEmpty
        ? rawDesc
        : 'قصة الفيلم: استمتع بمشاهدة أحدث الأفلام والمسلسلات بجودة عالية ومتعة لا تنتهي عبر منصة Jokar TV. تابع تفاصيل الأحداث والتشويق.';

    return VodDetails(
      name: (movieData['name'] ?? info['name'] ?? json['name'] ?? '').toString(),
      description: desc,
      duration: (info['duration'] ?? movieData['duration'] ?? '').toString(),
      rating: (info['rating'] ?? movieData['rating'] ?? '').toString(),
      director: (info['director'] ?? movieData['director'] ?? '').toString(),
      actors: (info['actors'] ?? info['cast'] ?? info['director'] ?? movieData['actors'] ?? '').toString(),
      genre: (info['genre'] ?? movieData['genre'] ?? '').toString(),
      releaseDate: (info['releasedate'] ?? info['release_date'] ?? movieData['releasedate'] ?? '').toString(),
      cover: (info['movie_image'] ?? info['cover'] ?? movieData['cover'] ?? '').toString(),
      containerExtension: (movieData['container_extension'] ?? json['container_extension'] ?? 'mp4').toString(),
    );
  }
}

class UserAccount {
  final String name;
  final String url;
  final String username;
  final String password;

  UserAccount({
    required this.name,
    required this.url,
    required this.username,
    required this.password,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      name: (json['name'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'username': username,
      'password': password,
    };
  }
}
