import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../utils/app_colors.dart';

class LanguageSwitcher extends StatefulWidget {
  final bool showAsDropdown;
  final bool showAsButtons;
  final bool compact;

  const LanguageSwitcher({
    Key? key,
    this.showAsDropdown = false,
    this.showAsButtons = false,
    this.compact = false,
  }) : super(key: key);

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _isChangingLanguage = false;

  Future<void> _changeLanguage(String newLanguage) async {
    if (_isChangingLanguage) return;

    setState(() {
      _isChangingLanguage = true;
    });

    try {
      final localization =
          Provider.of<LocalizationService>(context, listen: false);

      // Change language
      await localization.changeLanguage(newLanguage);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${'Language changed to'.tr()} ${localization.getNativeLanguageName(newLanguage)}'),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error changing language: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingLanguage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (widget.showAsDropdown) {
          return _buildDropdown(localization);
        } else if (widget.showAsButtons) {
          return _buildButtons(localization);
        } else {
          return _buildDefault(localization);
        }
      },
    );
  }

  Widget _buildDropdown(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryGreen),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: localization.currentLanguage,
          onChanged: _isChangingLanguage
              ? null
              : (String? newValue) {
                  if (newValue != null &&
                      newValue != localization.currentLanguage) {
                    _changeLanguage(newValue);
                  }
                },
          items: localization.getSupportedLanguages().map((languageCode) {
            return DropdownMenuItem<String>(
              value: languageCode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getLanguageIcon(languageCode),
                  const SizedBox(width: 8),
                  Text(
                    _getLanguageDisplayName(languageCode),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          icon: _isChangingLanguage
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                )
              : const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primaryGreen,
                ),
        ),
      ),
    );
  }

  Widget _buildButtons(LocalizationService localization) {
    if (_isChangingLanguage) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${'Changing language to'.tr()} ${localization.getNativeLanguageName(localization.currentLanguage)}...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: localization.getSupportedLanguages().map((languageCode) {
          final isSelected = languageCode == localization.currentLanguage;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                _changeLanguage(languageCode);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getLanguageIcon(languageCode),
                  if (!widget.compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      _getLanguageDisplayName(languageCode),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefault(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.language,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Language'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isChangingLanguage) ...[
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${'Changing language to'.tr()} ${localization.getNativeLanguageName(localization.currentLanguage)}...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...localization.getSupportedLanguages().map(
              (languageCode) {
                final isSelected = languageCode == localization.currentLanguage;
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      _changeLanguage(languageCode);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.lightGrey,
                      ),
                    ),
                    child: Row(
                      children: [
                        _getLanguageIcon(languageCode),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getLanguageDisplayName(languageCode),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _getLanguageIcon(String languageCode) {
    switch (languageCode) {
      case LocalizationService.englishCode:
        return const Text('🇬🇧', style: TextStyle(fontSize: 16));
      case LocalizationService.sinhalaCode:
        return const Text('🇱🇰', style: TextStyle(fontSize: 16));
      case LocalizationService.tamilCode:
        return const Text('🇱🇰', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.language,
            size: 16, color: AppColors.primaryGreen);
    }
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case LocalizationService.englishCode:
        return 'English';
      case LocalizationService.sinhalaCode:
        return 'සිංහල';
      case LocalizationService.tamilCode:
        return 'தமிழ்';
      default:
        return 'Unknown';
    }
  }
}

/// Simple language button for quick access
class LanguageButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LanguageButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return IconButton(
          onPressed: onPressed ?? () => _showLanguageSelector(context),
          icon: Stack(
            children: [
              const Icon(
                Icons.language,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _getLanguageShortCode(localization.currentLanguage),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageShortCode(String languageCode) {
    switch (languageCode) {
      case LocalizationService.englishCode:
        return 'EN';
      case LocalizationService.sinhalaCode:
        return 'SI';
      case LocalizationService.tamilCode:
        return 'TA';
      default:
        return 'EN';
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Language'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...LocalizationService().getSupportedLanguages().map(
                  (languageCode) => ListTile(
                    leading: Text(
                      _getLanguageFlag(languageCode),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(LocalizationService()
                        .getNativeLanguageName(languageCode)),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await LocalizationService().changeLanguage(languageCode);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case LocalizationService.englishCode:
        return '🇺🇸';
      case LocalizationService.sinhalaCode:
        return '🇱🇰';
      case LocalizationService.tamilCode:
        return '��🇰';
      default:
        return '🌍';
    }
  }
}
