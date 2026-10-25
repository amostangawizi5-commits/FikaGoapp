import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CustomerLocation {
  const CustomerLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.address,
    this.attribution,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String address;
  final String? attribution;
}

class LocationSearchResult {
  const LocationSearchResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  final String address;
  final double latitude;
  final double longitude;
  final int? placeId;
}

class LocationService {
  static Future<List<LocationSearchResult>> search(String query) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/api/location/search?q=${Uri.encodeQueryComponent(query)}',
      ).timeout(const Duration(seconds: 12));
      if (response['success'] == true && response['data'] is List) {
        final results = _searchResultsFromJson(response['data'] as List);
        if (results.isNotEmpty) return results;
      }
    } catch (_) {
      // Try the platform geocoder below if the API is unavailable.
    }

    try {
      final locations =
          await locationFromAddress(query).timeout(const Duration(seconds: 10));
      return locations
          .map((location) => LocationSearchResult(
                address: query,
                latitude: location.latitude,
                longitude: location.longitude,
              ))
          .toList();
    } catch (_) {
      throw Exception('Location search is unavailable');
    }
  }

  static List<LocationSearchResult> _searchResultsFromJson(List data) {
    return data
        .whereType<Map>()
        .map((item) {
          return LocationSearchResult(
            address: item['address']?.toString() ?? '',
            latitude: double.tryParse(item['latitude'].toString()) ?? 0,
            longitude: double.tryParse(item['longitude'].toString()) ?? 0,
            placeId: int.tryParse(item['place_id'].toString()),
          );
        })
        .where((item) =>
            item.address.isNotEmpty &&
            item.latitude >= -90 &&
            item.latitude <= 90 &&
            item.longitude >= -180 &&
            item.longitude <= 180)
        .toList();
  }

  static Future<CustomerLocation?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Android can still provide a recent cached fix while GPS is starting
        // or temporarily disabled. Use it only while it is reasonably fresh.
        final cached = await _getLastKnownPosition();
        if (_isRecent(cached, const Duration(minutes: 5))) {
          return await _locationFromPosition(cached!);
        }
        return null;
      }

      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever ||
            permission == LocationPermission.unableToDetermine) {
          return null;
        }
      }

      final cached = await _getLastKnownPosition();
      if (_isRecent(cached, const Duration(seconds: 30))) {
        return await _locationFromPosition(cached!);
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          position =
              _isRecent(cached, const Duration(minutes: 5)) ? cached : null;
        }
      }
      if (position == null) return null;

      return await _locationFromPosition(position);
    } catch (_) {
      return null;
    }
  }

  static Future<Position?> _getLastKnownPosition() async {
    if (kIsWeb) return null;
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  static bool _isRecent(Position? position, Duration maxAge) {
    if (position == null) return false;
    final age = DateTime.now().difference(position.timestamp);
    return !age.isNegative && age <= maxAge;
  }

  static Future<void> openRelevantSettings() async {
    if (kIsWeb) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      await Geolocator.openAppSettings();
    }
  }

  static Future<CustomerLocation> _locationFromPosition(
      Position position) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.reverseGeocode}?lat=${position.latitude}&lon=${position.longitude}',
      ).timeout(const Duration(seconds: 8));
      if (response['success'] == true && response['data'] is Map) {
        final data = response['data'] as Map;
        return CustomerLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          city: data['city']?.toString() ?? '',
          address: data['address']?.toString() ?? '',
          attribution: data['attribution']?.toString(),
        );
      }
    } catch (_) {
      // Fall back to the platform geocoder if the API is temporarily unavailable.
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      final place = placemarks.isEmpty ? null : placemarks.first;
      final city = _firstNonEmpty([
        place?.locality,
        place?.subAdministrativeArea,
        place?.administrativeArea,
      ]);
      final address = _firstNonEmpty([
        place?.name,
        place?.street,
        place?.subLocality,
        place?.thoroughfare,
      ]);
      return CustomerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city.isEmpty ? 'Location found' : city,
        address: [
          address,
          if (city.isNotEmpty &&
              !address.toLowerCase().contains(city.toLowerCase()))
            city,
        ].where((part) => part.isNotEmpty).join(', '),
      );
    } catch (_) {
      return CustomerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'Location found',
        address: '',
      );
    }
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
