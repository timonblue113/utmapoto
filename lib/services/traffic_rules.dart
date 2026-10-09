import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

enum RuleType {
  noTurn,
  noOvertake,
  residential,
  noStop,
  oddEvenParking,
  emergencyLane,
  camera,
}

class TrafficRule {
  final String id;
  final RuleType type;
  final String title;
  final double lat, lng, radius;
  final int? startMin, endMin; // phut trong ngay
  final String? parity; // 'odd' | 'even'

  TrafficRule({
    required this.id,
    required this.type,
    required this.title,
    required this.lat,
    required this.lng,
    required this.radius,
    this.startMin,
    this.endMin,
    this.parity,
  });

  static int? _min(String? s) {
    if (s == null) return null;
    final p = s.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  factory TrafficRule.fromJson(Map<String, dynamic> j) => TrafficRule(
        id: j['id'],
        type: RuleType.values.byName(j['type']),
        title: j['title'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radius: (j['radius'] as num).toDouble(),
        startMin: _min(j['start']),
        endMin: _min(j['end']),
        parity: j['parity'],
      );

  /// Quy dinh co dang co hieu luc o thoi diem [now] khong.
  bool isActive(DateTime now) {
    if (parity != null) {
      final isOdd = now.day.isOdd;
      if ((parity == 'odd') != isOdd) return false;
    }
    if (startMin != null && endMin != null) {
      final m = now.hour * 60 + now.minute;
      return startMin! <= endMin!
          ? (m >= startMin! && m < endMin!)
          : (m >= startMin! || m < endMin!);
    }
    return true;
  }
}

class TrafficRulesService {
  List<TrafficRule> _rules = [];

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/traffic_rules.json');
    _rules = (jsonDecode(raw) as List)
        .map((e) => TrafficRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cac canh bao dang hieu luc trong ban kinh quy dinh quanh vi tri.
  List<TrafficRule> nearby(double lat, double lng, DateTime now) {
    return _rules.where((r) {
      final d = Geolocator.distanceBetween(lat, lng, r.lat, r.lng);
      return d <= r.radius && r.isActive(now);
    }).toList();
  }
}
