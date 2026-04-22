import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/settings/data/repositories/settings_repository.dart';

class ReportDialog extends StatefulWidget {
  final String targetType;
  final String targetId;
  final SettingsRepository repository;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    required SettingsRepository repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        repository: repository,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    {'value': 'spam', 'label': 'Spam', 'icon': Icons.report_outlined},
    {'value': 'harassment', 'label': 'Quấy rối', 'icon': Icons.person_off_outlined},
    {'value': 'inappropriate', 'label': 'Không phù hợp', 'icon': Icons.block_outlined},
    {'value': 'violence', 'label': 'Bạo lực', 'icon': Icons.warning_amber_outlined},
    {'value': 'other', 'label': 'Khác', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.repository.reportContent(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason!,
        description: _selectedReason == 'other'
            ? _descriptionController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét trong 24h.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Không thể gửi báo cáo';
        if (e.toString().contains('409')) {
          msg = 'Bạn đã báo cáo nội dung này rồi';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: AppColors.warning, size: 22),
                SizedBox(width: 10),
                Text(
                  'Báo cáo nội dung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Chọn lý do báo cáo',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_reasons.length, (i) {
            final r = _reasons[i];
            final isSelected = _selectedReason == r['value'];
            return RadioListTile<String>(
              value: r['value'] as String,
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              title: Row(
                children: [
                  Icon(
                    r['icon'] as IconData,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    r['label'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              dense: true,
              visualDensity: VisualDensity.compact,
            );
          }),
          if (_selectedReason == 'other')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _descriptionController,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Mô tả thêm (tùy chọn)',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason != null && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: AppColors.warning.withValues(alpha: 0.4),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Gửi báo cáo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
