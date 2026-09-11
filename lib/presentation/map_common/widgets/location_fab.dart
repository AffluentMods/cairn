// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

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
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.locationServicesOff),
          action: SnackBarAction(
            label: l10n.locationOpenSettings,
            onPressed: Geolocator.openLocationSettings,
          ),
        ));
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
      final controller = ref.read(mapControllerProvider);

      // Move to the last-known position immediately, so the puck appears without
      // waiting on a fresh fix (Fix Pass 1 X1.3.5). The locate tap never starts a
      // data fetch; the viewport pipeline handles that when the camera settles.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        await controller?.moveCamera(
          CameraUpdate.newLatLngZoom(LatLng(last.latitude, last.longitude), 14),
        );
      }

      // Refine with a fresh fix, but never block: cap it at 8 seconds.
      try {
        final fresh = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        final worthMoving = last == null ||
            Geolocator.distanceBetween(last.latitude, last.longitude,
                    fresh.latitude, fresh.longitude) >
                50;
        if (worthMoving) {
          await controller?.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(fresh.latitude, fresh.longitude), 15),
          );
        }
      } on TimeoutException {
        if (last == null) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.locationNoFix)));
        }
      }
    } catch (_) {
      // A stale or failed fix just leaves the camera where it was; do not block.
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
      // No hero: Explore and Navigate both keep a LocationFab alive in the
      // IndexedStack, and a shared hero tag misplaces the button.
      heroTag: null,
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
