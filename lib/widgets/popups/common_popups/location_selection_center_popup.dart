import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

class LocationSelectionCenterPopup extends StatefulWidget {
  final String? initialAddress;
  final Function(String) onLocationSelected;
  final VoidCallback? onClose;

  const LocationSelectionCenterPopup({
    Key? key,
    this.initialAddress,
    required this.onLocationSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<LocationSelectionCenterPopup> createState() =>
      _LocationSelectionCenterPopupState();
}

class _LocationSelectionCenterPopupState
    extends State<LocationSelectionCenterPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late TextEditingController _addressController;

  final List<String> _predefinedLocations = [
    'Colombo, Sri Lanka',
    'Kandy, Sri Lanka',
    'Galle, Sri Lanka',
    'Jaffna, Sri Lanka',
    'Anuradhapura, Sri Lanka',
    'Batticaloa, Sri Lanka',
    'Negombo, Sri Lanka',
    'Kurunegala, Sri Lanka',
  ];

  @override
  void initState() {
    super.initState();

    _addressController =
        TextEditingController(text: widget.initialAddress ?? '');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _closePopup() async {
    await _animationController.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  void _selectLocation(String address) {
    widget.onLocationSelected(address);
    _closePopup();
  }

  void _confirmCustomLocation() {
    if (_addressController.text.trim().isNotEmpty) {
      _selectLocation(_addressController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 340,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with close button
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Location',
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _closePopup,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Custom address input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Custom Address',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                hintText: 'Type your address here...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lightGrey.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                                suffixIcon: GestureDetector(
                                  onTap: _confirmCustomLocation,
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              maxLines: 2,
                              onSubmitted: (_) => _confirmCustomLocation(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Predefined locations
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Popular Locations',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Location options
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.builder(
                            itemCount: _predefinedLocations.length,
                            itemBuilder: (context, index) {
                              final location = _predefinedLocations[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectLocation(location),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGrey
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.lightGrey
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: AppColors.primaryGreen,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              location,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppColors.textSecondary,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Static method to show the popup
  static void show(
    BuildContext context, {
    String? initialAddress,
    required Function(String) onLocationSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return LocationSelectionCenterPopup(
          initialAddress: initialAddress,
          onLocationSelected: onLocationSelected,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
