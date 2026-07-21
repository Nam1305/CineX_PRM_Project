import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkState { unknown, online, offline }

/// Tracks the device network link for UX. It is not used as the source of
/// truth for writes: every write still has to be accepted by the API first.
class NetworkStatusProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkState _state = NetworkState.unknown;

  NetworkState get state => _state;
  bool get isOnline => _state == NetworkState.online;
  bool get isOffline => _state == NetworkState.offline;

  NetworkStatusProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _update(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  Future<void> _update(List<ConnectivityResult> results) async {
    final next = results.any((result) => result != ConnectivityResult.none)
        ? NetworkState.online
        : NetworkState.offline;
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
