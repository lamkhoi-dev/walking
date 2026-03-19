import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/feed_bloc.dart';
import '../widgets/post_card.dart';
import 'package:go_router/go_router.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _scrollController = ScrollController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(const FeedLoadRequested());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedBloc>().add(const FeedLoadMoreRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _filterLabel {
    switch (_selectedFilter) {
      case 'all':
        return 'Tất cả';
      case 'public':
        return 'Công khai';
      default:
        return 'Tất cả';
    }
  }

  IconData get _filterIcon {
    switch (_selectedFilter) {
      case 'all':
        return Icons.all_inclusive_rounded;
      case 'public':
        return Icons.public_rounded;
      default:
        return Icons.all_inclusive_rounded;
    }
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        selected: _selectedFilter,
        onSelected: (value) {
          Navigator.pop(context);
          if (value != _selectedFilter) {
            setState(() => _selectedFilter = value);
            context.read<FeedBloc>().add(FeedFilterChanged(value));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Feed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            actions: [
              GestureDetector(
                onTap: _showFilterPicker,
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_filterIcon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _filterLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        body: BlocBuilder<FeedBloc, FeedState>(
          builder: (context, state) {
            if (state is FeedLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is FeedError) return _buildError(state.message);
            if (state is FeedLoaded) return _buildFeed(state);
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/post/create');
          if (result == true && mounted) {
            context.read<FeedBloc>().add(const FeedRefreshRequested());
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildFeed(FeedLoaded state) {
    if (state.posts.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<FeedBloc>().add(const FeedRefreshRequested());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            );
          }
          final post = state.posts[index];
          return PostCard(
            post: post,
            onLike: () => context.read<FeedBloc>().add(FeedPostLikeToggled(post.id)),
            onComment: () => context.push('/post/${post.id}'),
            onTap: () => context.push('/post/${post.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.dynamic_feed_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Chưa có bài viết nào', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('Hãy là người đầu tiên chia sẻ!', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/post/create'),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Tạo bài viết'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: AppColors.danger.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          const Text('Không thể tải feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<FeedBloc>().add(const FeedLoadRequested()),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// === FILTER BOTTOM SHEET ===
class _FilterSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterSheet({required this.selected, required this.onSelected});

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
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Lọc bài viết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 4),
          Text('Hiển thị bài viết theo phạm vi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _FilterOption(
            icon: Icons.all_inclusive_rounded,
            title: 'Tất cả',
            subtitle: 'Bài viết công khai + nhóm của bạn',
            isSelected: selected == 'all',
            onTap: () => onSelected('all'),
            gradient: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
          ),
          _FilterOption(
            icon: Icons.public_rounded,
            title: 'Công khai',
            subtitle: 'Chỉ bài viết công khai toàn hệ thống',
            isSelected: selected == 'public',
            onTap: () => onSelected('public'),
            gradient: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
          ),
          // TODO: Sprint 3+ — dynamic group filters loaded from user's groups
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _FilterOption({
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
                    decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), shape: BoxShape.circle),
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
