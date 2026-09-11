// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../map_providers.dart';

/// Recenters the map on the user. Location permission is requested here, on the
/// first tap, never at app launch (spec Phase 1 acceptance).
class LocationFab extends ConsumerStatefulWidget {
  const LocationFab({super.key});

  @override
  ConsumerState<LocationFab> createState() => _LocationFabState();
}

class _LocationFabState extends ConsumerState<LocationFab> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _explain();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _explain();
        return;
      }

      ref.read(locationEnabledProvider.notifier).state = true;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final controller = ref.read(mapControllerProvider);
      await controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    } catch (_) {
      _explain();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _explain() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.locationPermissionBody),
        action: SnackBarAction(
          label: context.l10n.locationOpenSettings,
          onPressed: Geolocator.openAppSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'locationFab',
      onPressed: _onTap,
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.my_location),
    );
  }
}
