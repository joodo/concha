import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static late final SharedPreferencesWithCache i;
  static Future<void> init() async {
    i = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }
}
