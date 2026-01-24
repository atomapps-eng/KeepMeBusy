import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppImageCacheManager extends CacheManager {
  static const key = 'appImageCache';

  static final AppImageCacheManager _instance =
      AppImageCacheManager._internal();

  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30), // cache 30 hari
            maxNrOfCacheObjects: 200, // max 200 image
          ),
        );
}
