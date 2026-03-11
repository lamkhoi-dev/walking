import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';

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
                'Cùng nhau rèn luyện sức khỏe\nmỗi bước chân đều có ý nghĩa',
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
                text: 'Đăng nhập',
                icon: Icons.login,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Đăng ký tài khoản',
                isOutlined: true,
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 16),

              // Company registration link
              TextButton(
                onPressed: () {
                  // TODO: Open web portal link
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng truy cập web portal để đăng ký doanh nghiệp'),
                    ),
                  );
                },
                child: const Text(
                  'Đăng ký doanh nghiệp? →',
                  style: TextStyle(
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
