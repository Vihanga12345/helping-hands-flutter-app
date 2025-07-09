import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/localization_service.dart';
import '../utils/app_colors.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final Function(LatLng coordinates, String address) onLocationSelected;
  final bool showManualInput;

  const LocationPickerWidget({
    Key? key,
    this.initialLocation,
    this.initialAddress,
    required this.onLocationSelected,
    this.showManualInput = true,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _addressController = TextEditingController();

  LatLng _selectedLocation = const LatLng(6.9271, 79.8612); // Default Colombo
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  Offset _pinPosition = const Offset(0.5, 0.5); // Center of map (0-1 range)

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _addressController.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _initializeLocation() {
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _selectedAddress = widget.initialAddress ?? '';
    } else {
      _getCurrentLocation();
    }
    _getAddressFromCoordinates(_selectedLocation);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _pinPosition = const Offset(
              0.5, 0.5); // Center pin when getting current location
        });
        await _getAddressFromCoordinates(_selectedLocation);
        print(
            '✅ Current location found: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}');
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        _showErrorSnackBar('Error getting current location: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    if (!mounted) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      // Use free OpenStreetMap Nominatim API for reverse geocoding
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=16&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'HelpingHandsApp/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String address = '';
        if (data['display_name'] != null) {
          address = data['display_name'];
          // Clean up the address to show only relevant parts
          final parts = address.split(',');
          if (parts.length > 3) {
            // Take first 3-4 most relevant parts
            address = parts.take(4).join(', ');
          }
        } else {
          address =
              'Lat: ${coordinates.latitude.toStringAsFixed(6)}, Lng: ${coordinates.longitude.toStringAsFixed(6)}';
        }

        if (mounted) {
          setState(() {
            _selectedAddress = address;
            _addressController.text = address;
          });
          print('📍 Address found: $address');
        }
      } else {
        throw Exception('Failed to get address: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        String fallbackAddress =
            'Lat: ${coordinates.latitude.toStringAsFixed(6)}, Lng: ${coordinates.longitude.toStringAsFixed(6)}';
        setState(() {
          _selectedAddress = fallbackAddress;
          _addressController.text = fallbackAddress;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapTap(Offset localPosition, Size mapSize) {
    // Convert tap position to coordinates
    final dx = localPosition.dx / mapSize.width;
    final dy = localPosition.dy / mapSize.height;

    // Clamp values between 0 and 1
    final clampedDx = dx.clamp(0.0, 1.0);
    final clampedDy = dy.clamp(0.0, 1.0);

    // Update pin position
    setState(() {
      _pinPosition = Offset(clampedDx, clampedDy);
    });

    // Convert position to lat/lng (simplified mapping)
    // This creates a roughly 0.01 degree range around the current location
    final newLat = _selectedLocation.latitude + (0.5 - clampedDy) * 0.02;
    final newLng = _selectedLocation.longitude + (clampedDx - 0.5) * 0.02;

    final newLocation = LatLng(newLat, newLng);
    setState(() {
      _selectedLocation = newLocation;
    });

    _getAddressFromCoordinates(newLocation);
    print('📍 Map tapped at: $newLat, $newLng');
  }

  void _movePinToCenter() {
    setState(() {
      _pinPosition = const Offset(0.5, 0.5);
    });
  }

  void _confirmLocation() {
    String finalAddress = _addressController.text.trim();
    if (finalAddress.isEmpty) {
      finalAddress = _selectedAddress.isNotEmpty
          ? _selectedAddress
          : 'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}';
    }

    widget.onLocationSelected(_selectedLocation, finalAddress);
    print(
        '✅ Location confirmed: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}');
    print('📍 Address: $finalAddress');
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Location'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingLocation || _isLoadingAddress)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual address input
                  if (widget.showManualInput) ...[
                    Text(
                      'Selected Address'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Enter address manually'.tr(),
                        prefixIcon: const Icon(Icons.location_city,
                            color: AppColors.primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.primaryGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Map Section
                  Text(
                    'Interactive Map'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick action buttons
                  Flex(
                    direction: Axis.horizontal,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : () async {
                                  await _getCurrentLocation();
                                  if (_selectedAddress.isNotEmpty &&
                                      _selectedAddress !=
                                          'Tap on the map to select a location'
                                              .tr()) {
                                    _addressController.text = _selectedAddress;
                                    _showSuccessSnackBar(
                                        'Current location address selected automatically!');

                                    // Automatically confirm and pass the location back to the job request form
                                    await Future.delayed(const Duration(
                                        milliseconds:
                                            500)); // Brief delay to show success message

                                    // Directly call the onLocationSelected callback to update the job request form
                                    widget.onLocationSelected(
                                        _selectedLocation, _selectedAddress);
                                    Navigator.of(context).pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(
                            _isLoadingLocation
                                ? 'Getting Location...'.tr()
                                : 'Select Current Address'.tr(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Tap on the map to select a location'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Map Container
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primaryGreen, width: 2),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8F5E8),
                          Color(0xFFF0F8F0),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Map Background with Street Pattern
                          Positioned.fill(
                            child: CustomPaint(
                              painter: MapPainter(),
                            ),
                          ),

                          // Tap detector
                          Positioned.fill(
                            child: GestureDetector(
                              onTapDown: (details) {
                                _onMapTap(
                                    details.localPosition,
                                    Size(
                                        MediaQuery.of(context).size.width -
                                            64, // Account for padding
                                        280));
                              },
                              child: Container(),
                            ),
                          ),

                          // Draggable Pin
                          Positioned(
                            left: (_pinPosition.dx *
                                    (MediaQuery.of(context).size.width - 96)) -
                                12, // Account for pin width
                            top: (_pinPosition.dy * 280) -
                                24, // Account for pin height
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                final RenderBox box =
                                    context.findRenderObject() as RenderBox;
                                final mapWidth =
                                    MediaQuery.of(context).size.width - 64;
                                final mapHeight = 280.0;

                                setState(() {
                                  _pinPosition = Offset(
                                    ((_pinPosition.dx * mapWidth) +
                                                details.delta.dx)
                                            .clamp(0, mapWidth) /
                                        mapWidth,
                                    ((_pinPosition.dy * mapHeight) +
                                                details.delta.dy)
                                            .clamp(0, mapHeight) /
                                        mapHeight,
                                  );
                                });

                                // Update location based on pin position
                                final newLat = _selectedLocation.latitude +
                                    (0.5 - _pinPosition.dy) * 0.02;
                                final newLng = _selectedLocation.longitude +
                                    (_pinPosition.dx - 0.5) * 0.02;

                                setState(() {
                                  _selectedLocation = LatLng(newLat, newLng);
                                });

                                _getAddressFromCoordinates(_selectedLocation);
                              },
                              child: Stack(
                                children: [
                                  // Pin shadow
                                  Positioned(
                                    top: 2,
                                    left: 2,
                                    child: Icon(
                                      Icons.location_on,
                                      size: 40,
                                      color: AppColors.shadowColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  // Main pin
                                  Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: AppColors.primaryGreen,
                                  ),
                                  // Inner dot
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Map controls
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Column(
                              children: [
                                // Current location button
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadowColor
                                            .withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _getCurrentLocation,
                                    icon: Icon(
                                      Icons.my_location,
                                      color: _isLoadingLocation
                                          ? AppColors.textSecondary
                                          : AppColors.primaryGreen,
                                    ),
                                    iconSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Center pin button
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadowColor
                                            .withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _movePinToCenter,
                                    icon: const Icon(
                                      Icons.center_focus_strong,
                                      color: AppColors.primaryGreen,
                                    ),
                                    iconSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.primaryGreen, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Selected Location'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            if (_isLoadingAddress) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : 'Tap on the map to select a location'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.shadowColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm Location'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map background
class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Draw grid pattern
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some "streets" to make it look more map-like
    final streetPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.2)
      ..strokeWidth = 2;

    // Horizontal streets
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      streetPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      streetPaint,
    );

    // Vertical streets
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      streetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper function to show location picker as a bottom sheet
void showLocationPicker({
  required BuildContext context,
  LatLng? initialLocation,
  String? initialAddress,
  required Function(LatLng coordinates, String address) onLocationSelected,
  bool showManualInput = true,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LocationPickerWidget(
      initialLocation: initialLocation,
      initialAddress: initialAddress,
      onLocationSelected: onLocationSelected,
      showManualInput: showManualInput,
    ),
  );
}
