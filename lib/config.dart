/// API key duoc truyen luc build:
///   flutter build apk --dart-define=VIETMAP_API_KEY=xxxx
/// Tren GitHub Actions: them secret VIETMAP_API_KEY (Settings > Secrets > Actions).
class AppConfig {
  static const String apiKey =
      String.fromEnvironment('VIETMAP_API_KEY', defaultValue: '');

  static String get mapStyle =>
      'https://maps.vietmap.vn/api/maps/light/styles.json?apikey=$apiKey';

  static String get searchUrl => 'https://maps.vietmap.vn/api/search/v3';
  static String get placeUrl => 'https://maps.vietmap.vn/api/place/v3';
}
