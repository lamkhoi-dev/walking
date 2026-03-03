import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/group_repository.dart';

/// Widget for searching and selecting company members
/// Used in create/edit group pages
class MemberSelector extends StatefulWidget {
  final GroupRepository repository;
  final List<String> selectedMemberIds;
  final List<String> excludeMemberIds;
  final ValueChanged<List<String>> onChanged;

  const MemberSelector({
    super.key,
    required this.repository,
    required this.selectedMemberIds,
    this.excludeMemberIds = const [],
    required this.onChanged,
  });

  @override
  State<MemberSelector> createState() => _MemberSelectorState();
}

class _MemberSelectorState extends State<MemberSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<MemberModel> _members = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedMemberIds);
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await widget.repository.getCompanyMembers(search: search);
      setState(() {
        _members = members
            .where((m) => !widget.excludeMemberIds.contains(m.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách thành viên';
        _isLoading = false;
      });
    }
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedIds.contains(memberId)) {
        _selectedIds.remove(memberId);
      } else {
        _selectedIds.add(memberId);
      }
    });
    widget.onChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Chọn thành viên',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(width: 8),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedIds.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm thành viên...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _loadMembers();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (value) {
            _loadMembers(search: value.trim().isNotEmpty ? value.trim() : null);
          },
        ),
        const SizedBox(height: 12),

        // Member list
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Text(_error!, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadMembers(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          )
        else if (_members.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Không tìm thấy thành viên',
                style: AppTextStyles.bodySmall,
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _members.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final member = _members[index];
                final isSelected = _selectedIds.contains(member.id);

                return InkWell(
                  onTap: () => _toggleMember(member.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Avatar
                        AvatarWidget(
                          imageUrl: member.avatar,
                          name: member.fullName,
                          size: 36,
                        ),
                        const SizedBox(width: 10),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (member.email != null || member.phone != null)
                                Text(
                                  member.email ?? member.phone ?? '',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
