import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/feed_repository.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  String _visibility = 'public';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty || _images.isNotEmpty;

  String get _visibilityLabel {
    switch (_visibility) {
      case 'public':
        return 'Công khai';
      case 'all_groups':
        return 'Tất cả nhóm';
      default:
        return 'Công khai';
    }
  }

  IconData get _visibilityIcon {
    switch (_visibility) {
      case 'public':
        return Icons.public_rounded;
      case 'all_groups':
        return Icons.groups_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= 4) return;
    final remaining = 4 - _images.length;
    final picked = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final xFile in picked) {
          if (_images.length < 4) _images.add(File(xFile.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submitPost() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<FeedRepository>();
      await repo.createPost(
        content: _contentController.text.trim(),
        visibility: _visibility,
        images: _images.isNotEmpty ? _images : null,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisibilitySheet(
        selected: _visibility,
        onSelected: (v) {
          setState(() => _visibility = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tạo bài viết',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _canPost && !_isSubmitting ? _submitPost : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Đăng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visibility chip
                  GestureDetector(
                    onTap: _showVisibilityPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.secondary.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_visibilityIcon, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            _visibilityLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content input
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 5,
                    maxLength: 2000,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 16),
                      border: InputBorder.none,
                      counterStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textMain),
                  ),

                  // Image preview grid
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildImageGrid(),
                  ],
                ],
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_images.length, (index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_images[index], width: 100, height: 100, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.photo_library_rounded,
            label: 'Ảnh',
            color: AppColors.success,
            badgeCount: _images.length,
            onTap: _images.length < 4 ? _pickImages : null,
          ),
          const SizedBox(width: 16),
          _ToolbarButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            color: AppColors.info,
            onTap: _images.length < 4
                ? () async {
                    final picked = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
                    );
                    if (picked != null) setState(() => _images.add(File(picked.path)));
                  }
                : null,
          ),
          const SizedBox(width: 16),
          _ToolbarButton(
            icon: Icons.emoji_events_rounded,
            label: 'Thành tích',
            color: AppColors.warning,
            onTap: () {
              // TODO: Sprint 4+ — show contest achievement picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng sắp ra mắt! 🏆')),
              );
            },
          ),
          const Spacer(),
          Text(
            '${_images.length}/4 ảnh',
            style: TextStyle(
              fontSize: 12,
              color: _images.length >= 4 ? AppColors.warning : AppColors.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// === VISIBILITY BOTTOM SHEET ===
class _VisibilitySheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _VisibilitySheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ai có thể xem?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn phạm vi hiển thị bài viết',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _VisibilityOption(
            icon: Icons.public_rounded,
            title: 'Công khai',
            subtitle: 'Tất cả mọi người đều xem được',
            isSelected: selected == 'public',
            onTap: () => onSelected('public'),
            gradient: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
          ),
          _VisibilityOption(
            icon: Icons.groups_rounded,
            title: 'Tất cả nhóm của tôi',
            subtitle: 'Chỉ thành viên trong nhóm bạn tham gia',
            isSelected: selected == 'all_groups',
            onTap: () => onSelected('all_groups'),
            gradient: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? gradient[0] : AppColors.divider.withValues(alpha: 0.6),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? gradient[0].withValues(alpha: 0.06) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  )
                else
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
