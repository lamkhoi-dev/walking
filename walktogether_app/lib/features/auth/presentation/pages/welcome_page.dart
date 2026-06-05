import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/language_toggle.dart';

/// Welcome/Landing page — first screen for unauthenticated users
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Language Selector Row
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: const LanguageToggle(),
                ),
              ),
              
              const Spacer(flex: 2),

              // Logo & Title
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/runly_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Runly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.welcome_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Buttons
              CustomButton(
                text: 'auth.login'.tr(),
                icon: Icons.login,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'auth.register'.tr(),
                isOutlined: true,
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 16),

              // Company registration link
              TextButton(
                onPressed: () {
                  // TODO: Open web portal link
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('auth.company_register_hint'.tr()),
                    ),
                  );
                },
                child: Text(
                  'auth.register_company'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
