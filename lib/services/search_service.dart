import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import '../config.dart';

class PlaceResult {
  final String name;
  final String address;
  final String refId;
  PlaceResult(this.name, this.address, this.refId);
}

/// Tim kiem dia diem qua Vietmap Search v3 / Place v3.
/// Luu y: ten truong JSON lay theo tai lieu Vietmap; hay doi chieu neu API doi.
class SearchService {
  Future<List<PlaceResult>> search(String text, {double? lat, double? lng}) async {
    final uri = Uri.parse(AppConfig.searchUrl).replace(queryParameters: {
      'apikey': AppConfig.apiKey,
      'text': text,
      if (lat != null && lng != null) 'focus': '$lat,$lng',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => PlaceResult(
              (e['name'] ?? '').toString(),
              (e['address'] ?? '').toString(),
              (e['ref_id'] ?? '').toString(),
            ))
        .toList();
  }

  Future<LatLng?> resolve(String refId) async {
    final uri = Uri.parse(AppConfig.placeUrl).replace(queryParameters: {
      'apikey': AppConfig.apiKey,
      'refid': refId,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final lat = j['lat'], lng = j['lng'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }
}
