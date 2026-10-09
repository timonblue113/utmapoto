import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class SpeedZone {
  final double lat, lng, radius;
  final int limit;
  SpeedZone(this.lat, this.lng, this.radius, this.limit);
}

class SpeedInfo {
  final int? current;
  final int? next;
  final int? nextDistanceM;
  const SpeedInfo({this.current, this.next, this.nextDistanceM});
}

class SpeedLimitService {
  List<SpeedZone> _zones = [];

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/speed_zones.json');
    _zones = (jsonDecode(raw) as List)
        .map((e) => SpeedZone(
              (e['lat'] as num).toDouble(),
              (e['lng'] as num).toDouble(),
              (e['radius'] as num).toDouble(),
              e['limit'] as int,
            ))
        .toList();
  }

  SpeedInfo lookup(double lat, double lng) {
    SpeedZone? cur;
    SpeedZone? next;
    double nextD = double.infinity;
    for (final z in _zones) {
      final d = Geolocator.distanceBetween(lat, lng, z.lat, z.lng);
      if (d <= z.radius) {
        cur = z;
      } else if (d - z.radius < nextD && d - z.radius < 1500) {
        nextD = d - z.radius;
        next = z;
      }
    }
    return SpeedInfo(
      current: cur?.limit,
      next: next?.limit,
      nextDistanceM: next == null ? null : nextD.round(),
    );
  }
}
