import 'package:geolocator/geolocator.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class GoogleMapsService {
  // Default location (Colombo, Sri Lanka)
  static const LatLng defaultLocation = LatLng(6.9271, 79.8612);

  /// Get current location using device GPS
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions permanently denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates (simplified without Google API)
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // Since we can't use Google Geocoding API, return coordinates as address
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      print('Error getting address: $e');
      return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Get coordinates from address (simplified without Google API)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      // Simple parsing for coordinate input
      if (address.contains('Lat:') && address.contains('Lng:')) {
        final parts = address.split(',');
        if (parts.length >= 2) {
          final latPart = parts[0].replaceAll('Lat:', '').trim();
          final lngPart = parts[1].replaceAll('Lng:', '').trim();

          final lat = double.tryParse(latPart);
          final lng = double.tryParse(lngPart);

          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }

      // For other addresses, return null (can't geocode without API)
      print('⚠️ Address geocoding not available without Google API');
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }
}
