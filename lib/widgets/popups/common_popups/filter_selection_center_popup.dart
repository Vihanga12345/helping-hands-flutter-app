import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

class FilterSelectionCenterPopup extends StatefulWidget {
  final String currentFilter;
  final Function(String) onFilterSelected;
  final VoidCallback? onClose;

  const FilterSelectionCenterPopup({
    Key? key,
    required this.currentFilter,
    required this.onFilterSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<FilterSelectionCenterPopup> createState() =>
      _FilterSelectionCenterPopupState();
}

class _FilterSelectionCenterPopupState extends State<FilterSelectionCenterPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'All', 'label': 'All Jobs', 'icon': Icons.list_alt},
    {
      'value': 'Active',
      'label': 'Active Jobs',
      'icon': Icons.play_circle_outline
    },
    {
      'value': 'Completed',
      'label': 'Completed Jobs',
      'icon': Icons.check_circle_outline
    },
    {
      'value': 'Cancelled',
      'label': 'Cancelled Jobs',
      'icon': Icons.cancel_outlined
    },
  ];

  @override
  void initState() {
    super.initState();

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
    _animationController.dispose();
    super.dispose();
  }

  void _closePopup() async {
    await _animationController.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
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
                  height: 380,
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
                              'Filter Jobs',
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

                      // Filter options
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: _filterOptions
                                .map(
                                  (option) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          widget.onFilterSelected(
                                              option['value']);
                                          _closePopup();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: widget.currentFilter ==
                                                    option['value']
                                                ? AppColors.primaryGreen
                                                    .withOpacity(0.1)
                                                : AppColors.lightGrey
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: widget.currentFilter ==
                                                      option['value']
                                                  ? AppColors.primaryGreen
                                                  : AppColors.lightGrey
                                                      .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                option['icon'],
                                                color: widget.currentFilter ==
                                                        option['value']
                                                    ? AppColors.primaryGreen
                                                    : AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                option['label'],
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: widget.currentFilter ==
                                                          option['value']
                                                      ? AppColors.primaryGreen
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (widget.currentFilter ==
                                                  option['value'])
                                                Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.primaryGreen,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
    required String currentFilter,
    required Function(String) onFilterSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return FilterSelectionCenterPopup(
          currentFilter: currentFilter,
          onFilterSelected: onFilterSelected,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
