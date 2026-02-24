import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Lightweight connectivity monitor.
/// Listens to connectivity changes and provides a ValueNotifier
/// that widgets can use to show/hide offline banners.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void init() {
    // Check initial state
    try {
      Connectivity().checkConnectivity().then((results) {
        isOnline.value = !results.contains(ConnectivityResult.none);
      }).catchError((_) {
        // Plugin not available — assume online
        isOnline.value = true;
      });

      // Listen for changes
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        isOnline.value = !results.contains(ConnectivityResult.none);
      }, onError: (_) {
        // Plugin stream error — stay online
        isOnline.value = true;
      });
    } catch (_) {
      // MissingPluginException — plugin not registered (e.g. hot restart)
      isOnline.value = true;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// A small banner widget that shows "Offline" when connectivity is lost.
/// Place this at the top of the main screen body.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService().isOnline,
      builder: (context, online, _) {
        if (online) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.orange.shade800,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Keine Internetverbindung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
