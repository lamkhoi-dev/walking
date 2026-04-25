import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/repositories/settings_repository.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            context.read<SettingsCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            context.read<SettingsCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final settings = state.settings;
          if (settings == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể tải cài đặt',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<SettingsCubit>().loadSettings(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationSection(settings),
                const SizedBox(height: 20),
                _buildAccountSection(),
                const SizedBox(height: 20),
                _buildDangerZone(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== NOTIFICATION SECTION =====
  Widget _buildNotificationSection(UserSettings settings) {
    final notif = settings.notifications;
    return _SectionCard(
      title: 'Thông báo',
      icon: Icons.notifications_outlined,
      iconColor: AppColors.info,
      children: [
        _ToggleItem(
          icon: Icons.chat_bubble_outline,
          label: 'Tin nhắn chat',
          subtitle: 'Thông báo khi có tin nhắn mới',
          value: notif.chat,
          onChanged: (v) =>
              context.read<SettingsCubit>().toggleNotification('chat', v),
        ),
        _ToggleItem(
          icon: Icons.emoji_events_outlined,
          label: 'Cuộc thi',
          subtitle: 'Thông báo khi cuộc thi bắt đầu/kết thúc',
          value: notif.contest,
          onChanged: (v) =>
              context.read<SettingsCubit>().toggleNotification('contest', v),
        ),
        _ToggleItem(
          icon: Icons.flag_outlined,
          label: 'Mục tiêu hàng ngày',
          subtitle: 'Nhắc nhở khi gần đạt mục tiêu',
          value: notif.dailyGoal,
          onChanged: (v) =>
              context.read<SettingsCubit>().toggleNotification('dailyGoal', v),
        ),
        _ToggleItem(
          icon: Icons.bar_chart_rounded,
          label: 'Báo cáo tuần',
          subtitle: 'Tổng kết bước chân hàng tuần',
          value: notif.weeklyReport,
          onChanged: (v) => context
              .read<SettingsCubit>()
              .toggleNotification('weeklyReport', v),
          showDivider: false,
        ),
      ],
    );
  }

  // ===== ACCOUNT SECTION =====
  Widget _buildAccountSection() {
    return _SectionCard(
      title: 'Tài khoản',
      icon: Icons.person_outline,
      iconColor: AppColors.secondary,
      children: [
        _ActionItem(
          icon: Icons.lock_outline,
          label: 'Đổi mật khẩu',
          onTap: () => context.push('/settings/change-password'),
        ),
        _ActionItem(
          icon: Icons.person_off_outlined,
          label: 'Người đã chặn',
          onTap: () => context.push('/settings/blocked'),
        ),
        _ActionItem(
          icon: Icons.description_outlined,
          label: 'Điều khoản sử dụng',
          onTap: () => context.push('/terms'),
        ),
        _ActionItem(
          icon: Icons.shield_outlined,
          label: 'Chính sách bảo mật',
          onTap: () => launchUrl(
            Uri.parse('https://lamkhoi-dev.github.io/walking/'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  // ===== DANGER ZONE =====
  Widget _buildDangerZone() {
    return _SectionCard(
      title: 'Vùng nguy hiểm',
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.danger,
      children: [
        _ActionItem(
          icon: Icons.delete_forever_outlined,
          label: 'Xóa tài khoản',
          color: AppColors.danger,
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: AppColors.danger, size: 24),
            const SizedBox(width: 8),
            const Text('Xóa tài khoản?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động này không thể hoàn tác. Tất cả dữ liệu cá nhân, bước chân và cài đặt sẽ bị xóa.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nhập mật khẩu xác nhận',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<SettingsCubit>().deleteAccount(password);
              if (success && mounted) {
                // Let the AuthBloc handle routing automatically via GoRouter's refreshListenable
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            child: const Text('Xóa tài khoản', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ===== REUSABLE COMPONENTS =====

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 52, color: Colors.grey.shade100),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textMain;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: itemColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: itemColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
