import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';

import '../config.dart';
import '../services/epass_service.dart';
import '../services/search_service.dart';
import '../services/speed_limit_service.dart';
import '../services/traffic_rules.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final _plugin = VietMapNavigationPlugin();
  late MapOptions _options;
  MapNavigationViewController? _controller;
  RouteProgressEvent? _progress;
  bool _routeReady = false;
  bool _navigating = false;

  final _rules = TrafficRulesService();
  final _speedSvc = SpeedLimitService();
  final EpassService _epass = NoopEpassService();
  final _search = SearchService();
  final _searchCtrl = TextEditingController();

  StreamSubscription<Position>? _posSub;
  Position? _pos;
  double _speedKmh = 0;
  SpeedInfo _speedInfo = const SpeedInfo();
  List<TrafficRule> _warnings = [];
  List<PlaceResult> _results = [];
  int? _epassBalance;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (AppConfig.apiKey.isEmpty) {
      setState(() => _error =
          'Chua co VIETMAP_API_KEY. Build voi --dart-define=VIETMAP_API_KEY=...');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _error = 'Can cap quyen vi tri de dan duong.');
      return;
    }

    _options = _plugin.getDefaultOptions();
    _options.simulateRoute = false;
    _options.apiKey = AppConfig.apiKey;
    _options.mapStyle = AppConfig.mapStyle;
    _plugin.setDefaultOptions(_options);

    await _rules.load();
    await _speedSvc.load();
    _epassBalance = await _epass.balance();

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    setState(() => _ready = true);
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    setState(() {
      _pos = p;
      _speedKmh = (p.speed < 0 ? 0 : p.speed) * 3.6;
      _speedInfo = _speedSvc.lookup(p.latitude, p.longitude);
      _warnings = _rules.nearby(p.latitude, p.longitude, DateTime.now());
    });
  }

  Future<void> _routeTo(LatLng dest) async {
    final p = _pos ?? await Geolocator.getCurrentPosition();
    await _controller?.buildRoute(
      wayPoints: [LatLng(p.latitude, p.longitude), dest],
      profile: DrivingProfile.drivingTraffic,
    );
  }

  Future<void> _doSearch(String text) async {
    if (text.trim().isEmpty) return;
    final r = await _search.search(text, lat: _pos?.latitude, lng: _pos?.longitude);
    setState(() => _results = r);
  }

  Future<void> _pick(PlaceResult r) async {
    setState(() => _results = []);
    FocusScope.of(context).unfocus();
    final ll = await _search.resolve(r.refId);
    if (ll != null) await _routeTo(ll);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _controller?.onDispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))));
    }
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(children: [
        NavigationView(
          mapOptions: _options,
          onMapCreated: (c) => _controller = c,
          onRouteProgressChange: (e) => setState(() => _progress = e),
          onRouteBuilt: (_) => setState(() => _routeReady = true),
          onMapLongClick: (LatLng? ll, point) {
            if (ll != null) _routeTo(ll);
          },
          onNavigationFinished: () => setState(() {
            _navigating = false;
            _routeReady = false;
            _progress = null;
          }),
        ),
        // Dan duong: banner huong re (SDK cung cap)
        if (_navigating)
          SafeArea(child: BannerInstructionView(
            routeProgressEvent: _progress,
            instructionIcon: const Icon(Icons.navigation, color: Colors.white),
          ))
        else
          _searchBar(),
        // Canh bao giao thong
        Positioned(left: 12, right: 12, top: _navigating ? 140 : 120,
            child: _warningList()),
        // Toc do gioi han
        Positioned(left: 12, bottom: 140, child: _speedPanel()),
        // ePass
        if (_epassBalance != null)
          Positioned(right: 12, top: 120, child: Chip(
              avatar: const Icon(Icons.toll, size: 18),
              label: Text('ePass: $_epassBalance d'))),
        // Dieu khien
        Positioned(left: 0, right: 0, bottom: 0, child: _bottom()),
      ]),
    );
  }

  Widget _searchBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _doSearch,
                decoration: const InputDecoration(
                  hintText: 'Tim dia diem (hoac nhan giu tren ban do)',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_results.isNotEmpty)
              Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(shrinkWrap: true, children: [
                    for (final r in _results)
                      ListTile(title: Text(r.name), subtitle: Text(r.address),
                          onTap: () => _pick(r)),
                  ]),
                ),
              ),
          ]),
        ),
      );

  Widget _warningList() => Column(children: [
        for (final w in _warnings)
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              dense: true,
              leading: Icon(_iconFor(w.type), color: Colors.red),
              title: Text(w.title),
            ),
          ),
      ]);

  IconData _iconFor(RuleType t) => switch (t) {
        RuleType.noTurn => Icons.turn_right,
        RuleType.noOvertake => Icons.block,
        RuleType.residential => Icons.home_work,
        RuleType.noStop => Icons.do_not_disturb_on,
        RuleType.oddEvenParking => Icons.local_parking,
        RuleType.emergencyLane => Icons.emergency,
        RuleType.camera => Icons.videocam,
      };

  Widget _speedPanel() {
    final limit = _speedInfo.current;
    final over = limit != null && _speedKmh > limit + 5;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_speedInfo.next != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Chip(label: Text(
              'Tiep theo: ${_speedInfo.next} km/h sau ${_speedInfo.nextDistanceM} m')),
        ),
      Row(children: [
        _limitSign(limit),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: over ? Colors.red : Colors.black87,
              borderRadius: BorderRadius.circular(10)),
          child: Text('${_speedKmh.round()} km/h',
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
      if (over)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('QUA TOC DO!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
    ]);
  }

  Widget _limitSign(int? limit) => Container(
        width: 56, height: 56, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 5)),
        child: Text(limit?.toString() ?? '--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

  Widget _bottom() {
    if (_navigating) {
      return BottomActionView(
        recenterButton: const SizedBox.shrink(),
        controller: _controller,
        routeProgressEvent: _progress,
      );
    }
    if (_routeReady) {
      return SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          icon: const Icon(Icons.navigation),
          label: const Text('Bat dau dan duong'),
          onPressed: () {
            _controller?.startNavigation();
            setState(() => _navigating = true);
          },
        ),
      ));
    }
    return const SizedBox.shrink();
  }
}
