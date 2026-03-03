import 'package:flutter/material.dart';
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
        title: Text('Nhóm', style: AppTextStyles.heading3),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMain),
            onPressed: () => context.push('/groups/search'),
            tooltip: 'Tìm kiếm nhóm',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textMain),
            onPressed: () => _showQRScanner(context),
            tooltip: 'Quét QR',
          ),
        ],
      ),
      body: BlocBuilder<GroupListBloc, GroupListState>(
        builder: (context, state) {
          if (state is GroupListLoading) {
            return const LoadingWidget(message: 'Đang tải nhóm...');
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
              label: const Text('Tạo nhóm'),
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
              'Chưa có nhóm nào',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Tạo nhóm đầu tiên để bắt đầu kết nối với nhân viên'
                  : 'Bạn chưa tham gia nhóm nào. Hãy quét mã QR để tham gia!',
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
        title: const Text('Xóa nhóm'),
        content: Text('Bạn có chắc muốn xóa nhóm "$groupName"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GroupListBloc>().add(GroupDeleteRequested(groupId));
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.danger),
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
