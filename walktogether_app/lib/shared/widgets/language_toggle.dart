import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isVi = currentLocale.languageCode == 'vi';

    return Container(
      height: 32,
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: isVi ? 2 : 50,
            top: 2,
            bottom: 2,
            right: isVi ? 50 : 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isVi) {
                      context.setLocale(const Locale('vi'));
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '🇻🇳 VI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isVi ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isVi) {
                      context.setLocale(const Locale('en'));
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '🇬🇧 EN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: !isVi ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
