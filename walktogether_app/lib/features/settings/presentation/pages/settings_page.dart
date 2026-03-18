import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
                _buildDailyGoalSection(settings),
                const SizedBox(height: 20),
                _buildNotificationSection(settings),
                const SizedBox(height: 20),
                _buildUnitsSection(settings),
                const SizedBox(height: 20),
                _buildAccountSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== DAILY GOAL SECTION =====
  Widget _buildDailyGoalSection(UserSettings settings) {
    return _SectionCard(
      title: 'Mục tiêu hàng ngày',
      icon: Icons.flag_rounded,
      iconColor: AppColors.primary,
      children: [
        _GoalSlider(
          currentGoal: settings.dailyGoalSteps,
          onChanged: (value) {
            context.read<SettingsCubit>().updateDailyGoal(value);
          },
        ),
      ],
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

  // ===== UNITS SECTION =====
  Widget _buildUnitsSection(UserSettings settings) {
    return _SectionCard(
      title: 'Đơn vị đo',
      icon: Icons.straighten_rounded,
      iconColor: AppColors.warning,
      children: [
        _UnitSelector(
          currentUnit: settings.units,
          onChanged: (unit) {
            context.read<SettingsCubit>().updateUnits(unit);
          },
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
      ],
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

class _GoalSlider extends StatefulWidget {
  final int currentGoal;
  final ValueChanged<int> onChanged;

  const _GoalSlider({required this.currentGoal, required this.onChanged});

  @override
  State<_GoalSlider> createState() => _GoalSliderState();
}

class _GoalSliderState extends State<_GoalSlider> {
  late double _value;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _value = widget.currentGoal.toDouble();
  }

  @override
  void didUpdateWidget(_GoalSlider old) {
    super.didUpdateWidget(old);
    if (!_isDragging && old.currentGoal != widget.currentGoal) {
      _value = widget.currentGoal.toDouble();
    }
  }

  String _formatSteps(double v) {
    final n = v.round();
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎯',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatSteps(_value)} bước',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _value,
              min: 1000,
              max: 50000,
              divisions: 49,
              onChangeStart: (_) => _isDragging = true,
              onChanged: (v) {
                setState(() => _value = (v / 1000).round() * 1000.0);
              },
              onChangeEnd: (v) {
                _isDragging = false;
                widget.onChanged((v / 1000).round() * 1000);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1k', style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
                Text('50k', style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
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

class _UnitSelector extends StatelessWidget {
  final String currentUnit;
  final ValueChanged<String> onChanged;

  const _UnitSelector({
    required this.currentUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _UnitOption(
              label: 'Metric',
              subtitle: 'km, kg',
              icon: Icons.public_rounded,
              isSelected: currentUnit == 'metric',
              onTap: () => onChanged('metric'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _UnitOption(
              label: 'Imperial',
              subtitle: 'mi, lb',
              icon: Icons.flag_rounded,
              isSelected: currentUnit == 'imperial',
              onTap: () => onChanged('imperial'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? AppColors.primary : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textMain),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMain.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
