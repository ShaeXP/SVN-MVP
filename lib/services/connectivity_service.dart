import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service that monitors network connectivity state
class ConnectivityService extends GetxService {
  static ConnectivityService get instance {
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService(), permanent: true);
    }
    return Get.find<ConnectivityService>();
  }

  final _connectivity = Connectivity();
  final isOffline = false.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> _init() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectivity(results);
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking connectivity: $e');
      // Default to offline on error
      isOffline.value = true;
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasOffline = isOffline.value;
    // Consider offline if no connectivity or only bluetooth (which doesn't provide internet)
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none || r == ConnectivityResult.bluetooth);
    
    isOffline.value = offline;
    
    if (wasOffline != offline) {
      debugPrint('[ConnectivityService] Connectivity changed: ${offline ? "OFFLINE" : "ONLINE"}');
    }
  }

  /// Check if currently online (convenience getter)
  bool get isOnline => !isOffline.value;
}

