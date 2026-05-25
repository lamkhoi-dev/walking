import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/repositories/group_repository.dart';
import '../../../friend/data/repositories/friend_repository.dart';
import '../../../friend/data/models/friendship_model.dart';

enum _MemberSource { company, friends }

/// Unified member item for display (works for both company and friend sources)
class _DisplayMember {
  final String id;
  final String fullName;
  final String? avatar;
  final String? subtitle;

  const _DisplayMember({
    required this.id,
    required this.fullName,
    this.avatar,
    this.subtitle,
  });
}

/// Widget for searching and selecting company members + friends
/// Used in create/edit group pages
class MemberSelector extends StatefulWidget {
  final GroupRepository repository;
  final FriendRepository? friendRepository;
  final List<String> selectedMemberIds;
  final List<String> excludeMemberIds;
  final ValueChanged<List<String>> onChanged;

  const MemberSelector({
    super.key,
    required this.repository,
    this.friendRepository,
    required this.selectedMemberIds,
    this.excludeMemberIds = const [],
    required this.onChanged,
  });

  @override
  State<MemberSelector> createState() => _MemberSelectorState();
}

class _MemberSelectorState extends State<MemberSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<_DisplayMember> _members = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  String? _error;
  _MemberSource _source = _MemberSource.company;

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
      if (_source == _MemberSource.friends && widget.friendRepository != null) {
        await _loadFriends(search: search);
      } else {
        await _loadCompanyMembers(search: search);
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompanyMembers({String? search}) async {
    final members = await widget.repository.getCompanyMembers(search: search);
    setState(() {
      _members = members
          .where((m) => !widget.excludeMemberIds.contains(m.id))
          .map((m) => _DisplayMember(
                id: m.id,
                fullName: m.fullName,
                avatar: m.avatar,
                subtitle: m.email ?? m.phone,
              ))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _loadFriends({String? search}) async {
    final result = await widget.friendRepository!.getFriends(
      search: search,
      limit: 50,
    );
    final friends = result['friends'] as List<FriendUser>;
    setState(() {
      _members = friends
          .where((f) => !widget.excludeMemberIds.contains(f.id))
          .map((f) => _DisplayMember(
                id: f.id,
                fullName: f.fullName,
                avatar: f.avatar,
                subtitle: 'Bạn bè',
              ))
          .toList();
      _isLoading = false;
    });
  }

  void _switchSource(_MemberSource newSource) {
    if (_source == newSource) return;
    setState(() => _source = newSource);
    _searchController.clear();
    _loadMembers();
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
    final hasFriendRepo = widget.friendRepository != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text('Chọn thành viên', style: AppTextStyles.labelLarge),
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
        const SizedBox(height: 10),

        // Source tabs (only show if friendRepository is provided)
        if (hasFriendRepo) ...[
          Row(
            children: [
              _SourceChip(
                label: 'Công ty',
                icon: Icons.business_rounded,
                isSelected: _source == _MemberSource.company,
                onTap: () => _switchSource(_MemberSource.company),
              ),
              const SizedBox(width: 8),
              _SourceChip(
                label: 'Bạn bè',
                icon: Icons.people_rounded,
                isSelected: _source == _MemberSource.friends,
                onTap: () => _switchSource(_MemberSource.friends),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _source == _MemberSource.friends
                ? 'Tìm kiếm bạn bè...'
                : 'Tìm kiếm thành viên...',
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (value) {
            _loadMembers(
                search: value.trim().isNotEmpty ? value.trim() : null);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _source == _MemberSource.friends
                        ? Icons.people_outline_rounded
                        : Icons.person_search_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _source == _MemberSource.friends
                        ? 'Không tìm thấy bạn bè'
                        : 'Không tìm thấy thành viên',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
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
                                  : AppColors.textSecondary
                                      .withValues(alpha: 0.3),
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
                              if (member.subtitle != null)
                                Text(
                                  member.subtitle!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: _source == _MemberSource.friends
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
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

/// Source tab chip button
class _SourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
