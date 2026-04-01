import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../contest/data/repositories/contest_repository.dart';
import '../../../group/data/repositories/group_repository.dart';
import '../../data/repositories/feed_repository.dart';
import '../widgets/achievement_picker.dart';

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
  // Achievement sharing state
  String? _achievementContestId;
  String? _achievementContestName;
  int? _achievementRank;
  int? _achievementSteps;
  int? _achievementParticipants;
  // Group-specific posting state
  List<String> _selectedGroupIds = [];
  List<String> _selectedGroupNames = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty ||
      _images.isNotEmpty ||
      _achievementContestId != null;

  String get _visibilityLabel {
    switch (_visibility) {
      case 'public':
        return 'Công khai';
      case 'all_groups':
        return 'Tất cả nhóm';
      case 'groups':
        return _selectedGroupNames.isNotEmpty
            ? _selectedGroupNames.join(', ')
            : 'Nhóm cụ thể';
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
      case 'groups':
        return Icons.group_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= 8) return;
    final remaining = 8 - _images.length;
    final picked = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final xFile in picked) {
          if (_images.length < 8) {
            // Trim path to handle space in scaled filenames from image_picker
            final file = File(xFile.path.trim());
            if (file.existsSync()) {
              _images.add(file);
            }
          }
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
      String postContent = _contentController.text.trim();

      // If sharing a contest achievement, add readable text AND use API field
      String? postType;
      String? sharedContestId;
      if (_achievementContestId != null && _achievementRank != null) {
        postType = 'shared_contest';
        sharedContestId = _achievementContestId;
        // Add human-readable text for backwards compatibility
        final steps = _formatSteps(_achievementSteps ?? 0);
        final rankInfo = '🏆 Hạng #$_achievementRank với $steps bước trong "$_achievementContestName"';
        if (postContent.isEmpty) {
          postContent = rankInfo;
        } else {
          postContent = '$postContent\n$rankInfo';
        }
      }

      final repo = context.read<FeedRepository>();
      await repo.createPost(
        content: postContent,
        visibility: _visibility,
        visibleToGroupIds: _visibility == 'groups' ? _selectedGroupIds : null,
        images: _images.isNotEmpty ? _images : null,
        type: postType,
        sharedContestId: sharedContestId,
        achievementRank: _achievementRank,
        achievementSteps: _achievementSteps,
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

  void _showAchievementPicker() {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AchievementPicker(
        contestRepository: context.read<ContestRepository>(),
        currentUserId: currentUserId,
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          _achievementContestId = result.contest.id;
          _achievementContestName = result.contest.name;
          _achievementRank = result.rank;
          _achievementSteps = result.totalSteps;
          _achievementParticipants = result.totalParticipants;
        });
      }
    });
  }

  String _formatSteps(int steps) {
    if (steps < 1000) return steps.toString();
    if (steps < 10000) return '${(steps / 1000).toStringAsFixed(1)}K';
    return '${(steps / 1000).toStringAsFixed(0)}K';
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisibilitySheet(
        selected: _visibility,
        onSelected: (v) {
          Navigator.pop(context);
          if (v == 'groups') {
            _showGroupPicker();
          } else {
            setState(() {
              _visibility = v;
              _selectedGroupIds = [];
              _selectedGroupNames = [];
            });
          }
        },
      ),
    );
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GroupPickerSheet(
        groupRepository: context.read<GroupRepository>(),
        selectedIds: _selectedGroupIds,
      ),
    ).then((result) {
      if (result != null && result is Map<String, List<String>> && mounted) {
        setState(() {
          _visibility = 'groups';
          _selectedGroupIds = result['ids'] ?? [];
          _selectedGroupNames = result['names'] ?? [];
        });
      }
    });
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
                    textCapitalization: TextCapitalization.sentences,
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

                  // Achievement preview card
                  if (_achievementContestName != null) ...[
                    const SizedBox(height: 12),
                    _buildAchievementPreview(),
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

  Widget _buildAchievementPreview() {
    final rank = _achievementRank ?? 0;
    Color medalColor;
    IconData medalIcon;
    if (rank == 1) {
      medalColor = AppColors.goldMedal;
      medalIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      medalColor = AppColors.silverMedal;
      medalIcon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      medalColor = AppColors.bronzeMedal;
      medalIcon = Icons.emoji_events_rounded;
    } else {
      medalColor = AppColors.primary;
      medalIcon = Icons.leaderboard_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            medalColor.withValues(alpha: 0.08),
            medalColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: medalColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(medalIcon, size: 18, color: medalColor),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: medalColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _achievementContestName!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.directions_walk_rounded,
                        size: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Text(
                      '${_formatSteps(_achievementSteps ?? 0)} bước',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.people_rounded,
                        size: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Text(
                      '${_achievementParticipants ?? 0} người',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearAchievement,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAchievement() {
    setState(() {
      _achievementContestId = null;
      _achievementContestName = null;
      _achievementRank = null;
      _achievementSteps = null;
      _achievementParticipants = null;
    });
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
                    if (picked != null) {
                      final file = File(picked.path.trim());
                      if (file.existsSync()) setState(() => _images.add(file));
                    }
                  }
                : null,
          ),
          const SizedBox(width: 16),
          _ToolbarButton(
            icon: Icons.emoji_events_rounded,
            label: 'Thành tích',
            color: AppColors.warning,
            onTap: () => _showAchievementPicker(),
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
          _VisibilityOption(
            icon: Icons.group_rounded,
            title: 'Nhóm cụ thể',
            subtitle: 'Chọn nhóm cụ thể để đăng bài',
            isSelected: selected == 'groups',
            onTap: () => onSelected('groups'),
            gradient: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
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

// === GROUP PICKER BOTTOM SHEET ===
class _GroupPickerSheet extends StatefulWidget {
  final GroupRepository groupRepository;
  final List<String> selectedIds;

  const _GroupPickerSheet({
    required this.groupRepository,
    required this.selectedIds,
  });

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  bool _isLoading = true;
  List<_GroupItem> _groups = [];
  Set<String> _selected = {};
  Map<String, String> _nameMap = {};

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await widget.groupRepository.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups
              .map((g) => _GroupItem(id: g.id, name: g.name, memberCount: g.totalMembers))
              .toList();
          _nameMap = {for (final g in groups) g.id: g.name};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _confirm() {
    Navigator.pop(context, {
      'ids': _selected.toList(),
      'names': _selected.map((id) => _nameMap[id] ?? '').toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.group_rounded, color: Color(0xFFFF9800), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chọn nhóm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
                  ),
                ),
                FilledButton(
                  onPressed: _selected.isNotEmpty ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Xong (${_selected.length})'),
                ),
              ],
            ),
          ),
          Flexible(child: _buildContent()),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('Chưa có nhóm nào',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tạo hoặc tham gia nhóm trước!',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6))),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final group = _groups[index];
        final isSelected = _selected.contains(group.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleGroup(group.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                        Text('${group.memberCount} thành viên',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
                  else
                    Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey.shade300, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupItem {
  final String id;
  final String name;
  final int memberCount;
  const _GroupItem({required this.id, required this.name, required this.memberCount});
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
