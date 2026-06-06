import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../friend/data/repositories/friend_repository.dart';

/// Enhanced Profile page with stats, edit functionality, and beautiful UI
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;
  PersonalStats? _stats;
  bool _isLoadingStats = true;
  bool _statsLoaded = false;
  late DioClient _dioClient;

  // Posts tab state
  List<PostModel> _myPosts = [];
  bool _isLoadingPosts = true;
  int _postsPage = 1;
  int _postsTotalPages = 1;
  bool _isLoadingMorePosts = false;

  // Friend request badge
  int _pendingRequestCount = 0;
  late AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsLoaded) {
      _statsLoaded = true;
      _dioClient = context.read<DioClient>();
      _loadStats();
      _loadMyPosts();
      _loadPendingRequests();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    debugPrint('ProfilePage: _loadStats called');
    setState(() => _isLoadingStats = true);
    
    try {
      final repo = ProfileRepository(dio: _dioClient);
      debugPrint('ProfilePage: calling repo.getStats()');
      final stats = await repo.getStats();
      debugPrint('ProfilePage: got stats - today steps: ${stats.today.steps}, allTime: ${stats.allTime.totalSteps}');
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ProfilePage: Error loading stats: $e');
      debugPrint('ProfilePage: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          // Create empty stats as fallback
          _stats = PersonalStats(
            today: TodayStats(steps: 0, distance: 0, calories: 0),
            week: PeriodStats(totalSteps: 0, totalDistance: 0, totalCalories: 0, avgStepsPerDay: 0, daysTracked: 0),
            month: PeriodStats(totalSteps: 0, totalDistance: 0, totalCalories: 0, avgStepsPerDay: 0, daysTracked: 0),
            allTime: AllTimeStats(totalSteps: 0, totalDistance: 0, totalCalories: 0, daysTracked: 0, bestDay: null),
            streak: 0,
          );
        });
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      final repo = FriendRepository(dio: _dioClient);
      final result = await repo.getFriendRequests();
      final requests = result['requests'] as List;
      if (mounted) {
        setState(() => _pendingRequestCount = requests.length);
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('profile.change_avatar'.tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('profile.take_photo'.tr()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                title: Text('profile.choose_library'.tr()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85, requestFullMetadata: false);
    if (picked == null || !mounted) return;

    // Trim path to handle space in scaled filenames from image_picker
    final imagePath = picked.path.trim();

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('profile.uploading_photo'.tr()), duration: const Duration(seconds: 10)),
    );

    try {
      final repo = ProfileRepository(dio: _dioClient);
      await repo.uploadAvatar(File(imagePath));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.avatar_updated'.tr()), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        // Refresh user data
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error_generic'.tr(namedArgs: {'error': e.toString()})), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final company = state.company;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Combined gradient header + floating stats card
              SliverToBoxAdapter(
                child: _buildProfileHeader(user),
              ),

              // Quick Running Stats Row
              SliverToBoxAdapter(
                child: _buildQuickStats(),
              ),

              // Tab Bar — 3 tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: [
                      Tab(text: 'feed.title'.tr()),
                      Tab(text: 'profile.info_tab'.tr()),
                      Tab(text: 'profile.stats_tab'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(user),
                _buildInfoTab(user, company),
                _buildStatsTab(),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildProfileHeader(dynamic user) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Gradient header with rounded bottom corners
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: topPadding + 16, bottom: 80),
                decoration: const BoxDecoration(gradient: AppColors.profileGradient),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.5),
                            radius: 1.2,
                            colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.6, 0.3),
                            radius: 0.9,
                            colors: [AppColors.indigo.withValues(alpha: 0.2), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadAvatar(),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                                  ),
                                  child: AvatarWidget(imageUrl: user.avatar, name: user.fullName, size: 96),
                                ),
                                Positioned(
                                  bottom: 4, right: 6,
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.success, shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 6)],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white, shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 14, color: AppColors.indigo),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(user.role == 'company_admin' ? Icons.verified_rounded : Icons.person, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(width: 5),
                                Text(_roleLabel(user.role), style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_stats != null && _stats!.streak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Text('🔥', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Text('profile.n_day_streak'.tr(namedArgs: {'n': '${_stats!.streak}'}), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              if (_stats != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(_getRunningLevelEmoji(_stats!.allTime.totalSteps), style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Text(_getRunningLevel(_stats!.allTime.totalSteps), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Edit button
            Positioned(
              top: topPadding + 4, right: 4,
              child: IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: () => _showEditProfileDialog(user)),
            ),
            // Floating stats card
            Positioned(
              left: 20, right: 20, bottom: -28,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    _SocialStatColumn(
                      count: '${user.friendCount}',
                      label: 'profile.friends_label'.tr(),
                      onTap: () => context.push('/friends'),
                      badgeCount: _pendingRequestCount,
                      badgePulse: _badgePulseController,
                    ),
                    VerticalDivider(color: AppColors.divider.withValues(alpha: 0.5), width: 1, indent: 4, endIndent: 4),
                    _SocialStatColumn(count: '${user.postCount}', label: 'profile.posts_label'.tr(), onTap: () => _tabController.animateTo(0)),
                    VerticalDivider(color: AppColors.divider.withValues(alpha: 0.5), width: 1, indent: 4, endIndent: 4),
                    _SocialStatColumn(count: '${user.groupCount}', label: 'group.title'.tr()),
                  ]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
      ],
    );
  }


  Widget _buildQuickStats() {
    debugPrint('ProfilePage: _buildQuickStats - isLoading: $_isLoadingStats, stats: $_stats');
    
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _stats;
    if (stats == null) {
      debugPrint('ProfilePage: stats is null, returning empty');
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('profile.loading_stats'.tr())),
      );
    }

    debugPrint('ProfilePage: showing stats - allTime.totalSteps: ${stats.allTime.totalSteps}');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.directions_walk,
              value: _formatNumber(stats.allTime.totalSteps),
              label: 'profile.total_steps'.tr(),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.straighten,
              value: _formatDistance(stats.allTime.totalDistance),
              label: 'profile.distance_label'.tr(),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.local_fire_department,
              value: _formatCalories(stats.allTime.totalCalories),
              label: 'profile.calories_label'.tr(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(dynamic user, dynamic company) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info Section
          _buildSectionTitle('profile.personal_info'.tr(), Icons.person_outline),
          const SizedBox(height: 12),
          _buildInfoCard([
            _InfoItem(
              icon: Icons.email_outlined,
              label: 'auth.email'.tr(),
              value: user.email ?? 'profile.not_updated'.tr(),
            ),
            _InfoItem(
              icon: Icons.phone_outlined,
              label: 'auth.phone'.tr(),
              value: user.phone ?? 'profile.not_updated'.tr(),
            ),
            _InfoItem(
              icon: Icons.calendar_today_outlined,
              label: 'profile.joined_date'.tr(),
              value: user.createdAt != null ? _formatDate(user.createdAt!) : 'N/A',
            ),
          ]),

          const SizedBox(height: 24),

          // Company Section
          if (company != null) ...[
            _buildSectionTitle('profile.company_label'.tr(), Icons.business_outlined),
            const SizedBox(height: 12),
            _buildCompanyCard(company, user.role),
            const SizedBox(height: 24),
          ],

          // Actions Section
          _buildSectionTitle('profile.account_label'.tr(), Icons.settings_outlined),
          const SizedBox(height: 12),
          _buildActionsList(),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_run,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Runly v1.0.0',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;
    if (stats == null) {
      return Center(child: Text('common.no_data'.tr()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement Badges
          _buildAchievementBadges(),
          const SizedBox(height: 24),

          // Weekly Activity Chart
          _buildWeeklyActivityChart(),
          const SizedBox(height: 24),

          // Today Stats
          _buildSectionTitle('step_tracker.today'.tr(), Icons.today),
          const SizedBox(height: 12),
          _buildTodayCard(stats.today),
          const SizedBox(height: 24),

          // This Week
          _buildSectionTitle('profile.this_week'.tr(), Icons.date_range),
          const SizedBox(height: 12),
          _buildPeriodCard(stats.week, 'profile.week_unit'.tr()),
          const SizedBox(height: 24),

          // This Month
          _buildSectionTitle('profile.this_month'.tr(), Icons.calendar_month),
          const SizedBox(height: 12),
          _buildPeriodCard(stats.month, 'profile.month_unit'.tr()),
          const SizedBox(height: 24),

          // Personal Records
          _buildPersonalRecordsCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.heading4.copyWith(color: AppColors.textMain),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        entry.value.icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value.value,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 68, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanyCard(dynamic company, String userRole) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: company.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          company.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: AppTextStyles.heading4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${company.totalMembers} ${'group.members_label'.tr()}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(company.status),
            ],
          ),
          if (userRole == 'company_admin' && company.code != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.company_code'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        company.code!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: company.code!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('profile.code_copied'.tr()),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'profile.status_approved'.tr();
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'profile.status_pending'.tr();
        icon = Icons.access_time;
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.settings_outlined,
            label: 'profile.settings_label'.tr(),
            onTap: () => context.push('/settings'),
          ),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _buildActionItem(
            icon: Icons.notifications_outlined,
            label: 'profile.notifications_label'.tr(),
            onTap: () => context.push('/settings'),
          ),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _buildActionItem(
            icon: Icons.help_outline,
            label: 'profile.help_support'.tr(),
            onTap: () {
              // TODO: Implement help page
            },
          ),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _buildActionItem(
            icon: Icons.logout,
            label: 'auth.logout'.tr(),
            color: AppColors.danger,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
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
                color: itemColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(TodayStats today) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTodayStatItem(
            Icons.directions_walk,
            _formatNumber(today.steps),
            'profile.steps_label'.tr(),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildTodayStatItem(
            Icons.straighten,
            _formatDistance(today.distance),
            'profile.distance_label'.tr(),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildTodayStatItem(
            Icons.local_fire_department,
            _formatCalories(today.calories),
            'Calo',
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodCard(PeriodStats period, String periodName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPeriodStatItem(
                  _formatNumber(period.totalSteps),
                  'profile.total_steps'.tr(),
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildPeriodStatItem(
                  _formatDistance(period.totalDistance),
                  'profile.distance_label'.tr(),
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPeriodStatItem(
                  _formatNumber(period.avgStepsPerDay),
                  'profile.avg_per_day'.tr(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildPeriodStatItem(
                  '${period.daysTracked}',
                  'profile.active_days'.tr(),
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }


  void _showEditProfileDialog(dynamic user) {
    final nameController = TextEditingController(text: user.fullName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'profile.edit_profile'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'profile.full_name'.tr(),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return;
                    
                    try {
                      final dio = context.read<DioClient>();
                      final repo = ProfileRepository(dio: dio);
                      await repo.updateProfile(fullName: newName);
                      
                      // Refresh user data
                      if (context.mounted) {
                        context.read<AuthBloc>().add(AuthCheckRequested());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('profile.update_success'.tr()),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('common.error_generic'.tr(namedArgs: {'error': e.toString()})),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'profile.save_changes'.tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Text('auth.logout'.tr()),
          ],
        ),
        content: Text('auth.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'company_admin':
        return 'profile.admin_role'.tr();
      case 'member':
        return 'profile.member_role'.tr();
      default:
        return role;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  String _formatCalories(double calories) {
    if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}K';
    }
    return calories.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // === Running Level System ===
  String _getRunningLevel(int totalSteps) {
    if (totalSteps >= 500000) return 'Champion';
    if (totalSteps >= 200000) return 'Athlete';
    if (totalSteps >= 50000) return 'Runner';
    if (totalSteps >= 10000) return 'Walker';
    return 'Beginner';
  }

  String _getRunningLevelEmoji(int totalSteps) {
    if (totalSteps >= 500000) return '🏆';
    if (totalSteps >= 200000) return '💪';
    if (totalSteps >= 50000) return '🏃';
    if (totalSteps >= 10000) return '🚶';
    return '🌱';
  }

  // === Posts Tab — loads user's own posts ===
  Future<void> _loadMyPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _postsPage = 1;
        _isLoadingPosts = true;
      });
    }
    try {
      final repo = FeedRepository(_dioClient);
      final result = await repo.getFeed(filter: 'mine', page: _postsPage, limit: 20);
      if (mounted) {
        setState(() {
          if (refresh || _postsPage == 1) {
            _myPosts = result.posts;
          } else {
            _myPosts.addAll(result.posts);
          }
          _postsTotalPages = result.totalPages;
          _isLoadingPosts = false;
          _isLoadingMorePosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingMorePosts = false;
        });
      }
    }
  }

  void _loadMorePosts() {
    if (_isLoadingMorePosts || _postsPage >= _postsTotalPages) return;
    _postsPage++;
    _isLoadingMorePosts = true;
    _loadMyPosts();
  }

  Widget _buildPostsTab(dynamic user) {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'profile.no_posts'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                'profile.share_first_moment'.tr(),
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/post/create');
                  _loadMyPosts(refresh: true);
                  // Refresh social counts too
                  if (mounted) context.read<AuthBloc>().add(AuthCheckRequested());
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('feed.create_post'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          _loadMorePosts();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadMyPosts(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _myPosts.length + (_isLoadingMorePosts ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _myPosts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final post = _myPosts[index];
            return PostCard(
              post: post,
              isCompanyAdmin: user.role == 'company_admin',
              onLike: () async {
                try {
                  final repo = FeedRepository(_dioClient);
                  await repo.toggleLike(post.id);
                  _loadMyPosts(refresh: true);
                } catch (_) {}
              },
              onComment: () async {
                await context.push('/post/${post.id}');
                _loadMyPosts(refresh: true);
              },
              onTap: () async {
                await context.push('/post/${post.id}');
                _loadMyPosts(refresh: true);
              },
              onEdit: () => _showEditPostSheet(post),
              onDelete: () => _confirmDeletePost(post),
            );
          },
        ),
      ),
    );
  }

  void _showEditPostSheet(PostModel post) {
    final controller = TextEditingController(text: post.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('feed.edit_post'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'feed.post_content_hint'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    final repo = FeedRepository(_dioClient);
                    await repo.updatePost(post.id, content: controller.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      _loadMyPosts(refresh: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('profile.post_updated'.tr()), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('common.error_detail'.tr(namedArgs: {'error': e.toString()})), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('profile.save_changes'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('feed.delete_post_title'.tr()),
        content: Text('profile.delete_post_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = FeedRepository(_dioClient);
                await repo.deletePost(post.id);
                _loadMyPosts(refresh: true);
                if (mounted) context.read<AuthBloc>().add(AuthCheckRequested());
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('common.error_detail'.tr(namedArgs: {'error': e.toString()})), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  // === Achievement Badges ===
  Widget _buildAchievementBadges() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    final badges = <Map<String, dynamic>>[
      {'emoji': '🎯', 'title': 'profile.badge_first_step'.tr(), 'achieved': stats.allTime.totalSteps > 0, 'desc': 'profile.badge_first_step_desc'.tr()},
      {'emoji': '🏃', 'title': '10K Club', 'achieved': stats.allTime.totalSteps >= 10000, 'desc': 'profile.badge_10k_desc'.tr()},
      {'emoji': '🔥', 'title': 'Streak Master', 'achieved': stats.streak >= 7, 'desc': 'profile.badge_streak_desc'.tr()},
      {'emoji': '⭐', 'title': 'profile.golden_week'.tr(), 'achieved': stats.week.daysTracked >= 7, 'desc': 'profile.golden_week_desc'.tr()},
      {'emoji': '🏆', 'title': 'Marathon', 'achieved': stats.allTime.totalDistance >= 42195, 'desc': 'profile.badge_marathon_desc'.tr()},
      {'emoji': '💪', 'title': 'Calorie Burner', 'achieved': stats.allTime.totalCalories >= 10000, 'desc': 'profile.badge_calorie_desc'.tr()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('profile.achievement_badges'.tr(), Icons.military_tech_rounded),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: badges.length,
          itemBuilder: (ctx, i) {
            final b = badges[i];
            final achieved = b['achieved'] as bool;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: achieved ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: achieved ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Text(b['emoji'] as String, style: TextStyle(fontSize: 24, color: achieved ? null : Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: achieved ? AppColors.textMain : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          b['desc'] as String,
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // === Weekly Activity Mini Chart ===
  Widget _buildWeeklyActivityChart() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    final avg = stats.week.avgStepsPerDay;
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    // Simulate daily steps distribution around avg (since API gives avg only)
    final maxVal = avg > 0 ? avg * 1.5 : 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('profile.week_activity'.tr(), Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text('profile.average'.tr(), style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('${_formatNumber(avg)} ${'step_tracker.steps_per_day'.tr()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    // Distribute tracked days — assume first N days tracked
                    final isTracked = i < stats.week.daysTracked;
                    final barHeight = isTracked ? (avg / maxVal * 80).clamp(8.0, 80.0) : 8.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: isTracked ? AppColors.primary : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(dayLabels[i], style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === Personal Records Card ===
  Widget _buildPersonalRecordsCard() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('profile.personal_records'.tr(), Icons.emoji_events_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            children: [
              if (stats.allTime.bestDay != null)
                _recordRow('🏅', 'profile.best_day_steps'.tr(), 'profile.n_steps'.tr(namedArgs: {'n': _formatNumber(stats.allTime.bestDay!.steps)})),
              _recordRow('📏', 'profile.total_distance'.tr(), _formatDistance(stats.allTime.totalDistance)),
              _recordRow('🔥', 'profile.streak_consecutive'.tr(), 'profile.n_days'.tr(namedArgs: {'n': '${stats.streak}'})),
              _recordRow('📅', 'profile.active_days'.tr(), 'profile.n_days'.tr(namedArgs: {'n': '${stats.allTime.daysTracked}'})),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recordRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.orange.shade800))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade900)),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _SocialStatColumn extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;
  final int badgeCount;
  final AnimationController? badgePulse;

  const _SocialStatColumn({
    required this.count,
    required this.label,
    this.onTap,
    this.badgeCount = 0,
    this.badgePulse,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      if (onTap != null) ...[
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Blinking red badge
            if (badgeCount > 0 && badgePulse != null)
              Positioned(
                top: -4,
                right: 8,
                child: AnimatedBuilder(
                  animation: badgePulse!,
                  builder: (_, child) => Transform.scale(
                    scale: 0.85 + 0.15 * badgePulse!.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
