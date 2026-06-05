import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/group_list_bloc.dart';
import '../widgets/group_card.dart';

/// Page displaying all groups the user belongs to
class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  @override
  void initState() {
    super.initState();
    context.read<GroupListBloc>().add(GroupListLoadRequested());
  }

  bool _isCompanyAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role == 'company_admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isCompanyAdmin(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('group.title'.tr(), style: AppTextStyles.heading3),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMain),
            onPressed: () => context.push('/groups/search'),
            tooltip: 'group.search_title'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textMain),
            onPressed: () => _showQRScanner(context),
            tooltip: 'group.scan_qr'.tr(),
          ),
        ],
      ),
      body: BlocBuilder<GroupListBloc, GroupListState>(
        builder: (context, state) {
          if (state is GroupListLoading) {
            return LoadingWidget(message: 'group.loading_groups'.tr());
          }

          if (state is GroupListError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<GroupListBloc>().add(GroupListLoadRequested());
              },
            );
          }

          if (state is GroupListLoaded) {
            if (state.groups.isEmpty) {
              return _buildEmptyState(isAdmin);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GroupListBloc>().add(GroupListRefreshRequested());
              },
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return GroupCard(
                    group: group,
                    onTap: () => context.push('/groups/${group.id}'),
                    onLongPress: isAdmin
                        ? () => _showDeleteDialog(context, group.id, group.name)
                        : null,
                  );
                },
              ),
            );
          }

          return const LoadingWidget();
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/groups/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text('group.create_group'.tr()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'group.no_groups'.tr(),
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'group.no_groups_admin_hint'.tr()
                  : 'group.no_groups_member_hint'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('group.delete_group'.tr()),
        content: Text('group.delete_group_confirm'.tr(namedArgs: {'name': groupName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GroupListBloc>().add(GroupDeleteRequested(groupId));
            },
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRScanner(BuildContext context) {
    context.push('/groups/qr-scanner');
  }
}
