import 'package:flutter/material.dart';
import '../../services/admin_data_service.dart';
import '../../services/admin_auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/localization_service.dart';

class JobsVisibleToggleSwitch extends StatefulWidget {
  final String helperId;
  final String helperName;
  final bool initialValue;
  final Function(bool)? onChanged;
  final bool showLabel;
  final bool isCompact;

  const JobsVisibleToggleSwitch({
    Key? key,
    required this.helperId,
    required this.helperName,
    required this.initialValue,
    this.onChanged,
    this.showLabel = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<JobsVisibleToggleSwitch> createState() =>
      _JobsVisibleToggleSwitchState();
}

class _JobsVisibleToggleSwitchState extends State<JobsVisibleToggleSwitch> {
  late bool _isVisible;
  bool _isLoading = false;
  final AdminDataService _adminData = AdminDataService();
  final AdminAuthService _adminAuth = AdminAuthService();

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initialValue;
  }

  @override
  void didUpdateWidget(JobsVisibleToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _isVisible = widget.initialValue;
      });
    }
  }

  Future<void> _toggleVisibility(bool value) async {
    // Only allow admin users to toggle
    if (!_adminAuth.isLoggedIn) {
      _showErrorSnackBar('Admin access required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminData.toggleHelperJobsVisibility(
        widget.helperId,
        value,
      );

      if (success) {
        setState(() {
          _isVisible = value;
        });

        // Show success message
        _showSuccessSnackBar(value
            ? 'Jobs visibility enabled for ${widget.helperName}'.tr()
            : 'Jobs visibility disabled for ${widget.helperName}'.tr());

        // Notify parent widget
        widget.onChanged?.call(value);
      } else {
        _showErrorSnackBar('Failed to update jobs visibility'.tr());
      }
    } catch (e) {
      print('❌ Error toggling jobs visibility: $e');
      _showErrorSnackBar(
          'Error updating jobs visibility: ${e.toString()}'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show to admin users
    if (!_adminAuth.isLoggedIn) {
      return const SizedBox.shrink();
    }

    if (widget.isCompact) {
      return _buildCompactToggle();
    } else {
      return _buildFullToggle();
    }
  }

  Widget _buildCompactToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isVisible ? AppColors.primaryGreen : AppColors.mediumGrey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVisible ? Icons.visibility : Icons.visibility_off,
            size: 16,
            color: _isVisible ? AppColors.primaryGreen : AppColors.mediumGrey,
          ),
          const SizedBox(width: 6),
          Switch(
            value: _isVisible,
            onChanged: _isLoading ? null : _toggleVisibility,
            activeColor: AppColors.primaryGreen,
            activeTrackColor: AppColors.primaryGreen.withOpacity(0.3),
            inactiveThumbColor: AppColors.mediumGrey,
            inactiveTrackColor: AppColors.lightGrey,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (_isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isVisible
              ? AppColors.primaryGreen.withOpacity(0.3)
              : AppColors.lightGrey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color:
                    _isVisible ? AppColors.primaryGreen : AppColors.mediumGrey,
              ),
              const SizedBox(width: 8),
              if (widget.showLabel)
                Expanded(
                  child: Text(
                    'Jobs Visible'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isVisible
                          ? AppColors.primaryGreen
                          : AppColors.mediumGrey,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Switch(
                value: _isVisible,
                onChanged: _isLoading ? null : _toggleVisibility,
                activeColor: AppColors.primaryGreen,
                activeTrackColor: AppColors.primaryGreen.withOpacity(0.3),
                inactiveThumbColor: AppColors.mediumGrey,
                inactiveTrackColor: AppColors.lightGrey,
              ),
              if (_isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          if (widget.showLabel) ...[
            const SizedBox(height: 4),
            Text(
              _isVisible
                  ? 'Helper can see new job requests'.tr()
                  : 'Helper cannot see new job requests'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    _isVisible ? AppColors.textSecondary : AppColors.mediumGrey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
