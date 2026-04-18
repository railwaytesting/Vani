// Imported on Android/iOS only via conditional import in LocationService.dart
// Do NOT import this file directly.

import 'dart:async'; // ← fixes TimeoutException error
import 'package:geolocator/geolocator.dart';
import 'LocationService.dart';

Future<LocationResult> getCurrentLocation() async {
  // 1. Check if location services are enabled on device
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return const LocationResult(
      isAvailable: false,
      error: 'Location services are disabled. Please enable GPS in settings.',
    );
  }

  // 2. Check and request permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        isAvailable: false,
        error: 'Location permission denied.',
      );
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return const LocationResult(
      isAvailable: false,
      error: 'Location permission permanently denied. Enable in app settings.',
    );
  }

  // 3. Get position — high accuracy with timeout
  try {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    return LocationResult(
      isAvailable: true,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } on TimeoutException {
    // High accuracy timed out — try last known cached position
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          isAvailable: true,
          latitude: last.latitude,
          longitude: last.longitude,
        );
      }
    } catch (_) {}
    return const LocationResult(
      isAvailable: false,
      error: 'GPS timed out and no cached position available.',
    );
  } catch (e) {
    return LocationResult(
      isAvailable: false,
      error: 'GPS error: ${e.toString()}',
    );
  }
}
