import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSection(
                '1. Chấp nhận điều khoản',
                'Khi tạo tài khoản và sử dụng Runly, bạn đồng ý tuân thủ tất cả các điều khoản được nêu trong tài liệu này. Nếu bạn không đồng ý với bất kỳ điều khoản nào, vui lòng không sử dụng ứng dụng.',
              ),
              _buildSection(
                '2. Nội dung người dùng',
                'Runly cho phép người dùng đăng bài viết, bình luận và tin nhắn. Khi sử dụng các tính năng này, bạn cam kết:\n'
                    '\n• Không đăng nội dung phản cảm, khiêu dâm, hoặc vi phạm pháp luật.\n'
                    '• Không đăng nội dung bạo lực, đe dọa, hoặc kích động thù hận.\n'
                    '• Không quấy rối, xúc phạm, hoặc phân biệt đối xử với người dùng khác.\n'
                    '• Không đăng thông tin sai lệch hoặc spam.\n'
                    '\nVi phạm các quy định trên sẽ dẫn đến việc xóa nội dung và có thể bị khóa tài khoản vĩnh viễn. Chúng tôi cam kết xử lý các báo cáo vi phạm trong vòng 24 giờ.',
              ),
              _buildSection(
                '3. Quyền báo cáo và chặn',
                'Bạn có quyền:\n'
                    '\n• Báo cáo bất kỳ nội dung nào vi phạm quy định cộng đồng.\n'
                    '• Chặn người dùng khác để không nhìn thấy nội dung từ họ.\n'
                    '• Nội dung từ người dùng bị chặn sẽ được ẩn khỏi bảng tin của bạn ngay lập tức.\n'
                    '\nKhi bạn báo cáo nội dung, đội ngũ quản trị sẽ xem xét và xử lý trong thời gian sớm nhất.',
              ),
              _buildSection(
                '4. Xóa tài khoản',
                'Bạn có quyền xóa tài khoản bất cứ lúc nào thông qua mục Cài đặt trong ứng dụng. Khi xóa tài khoản:\n'
                    '\n• Thông tin cá nhân (tên, email, số điện thoại, ảnh đại diện) sẽ được xóa.\n'
                    '• Dữ liệu bước chân và cài đặt cá nhân sẽ được xóa.\n'
                    '• Bạn sẽ được gỡ khỏi tất cả các nhóm.\n'
                    '• Hành động này không thể hoàn tác.',
              ),
              _buildSection(
                '5. Quyền riêng tư',
                'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn:\n'
                    '\n• Thông tin cá nhân được bảo mật theo chính sách riêng tư.\n'
                    '• Dữ liệu bước chân chỉ được sử dụng trong phạm vi ứng dụng.\n'
                    '• Chúng tôi không chia sẻ dữ liệu cá nhân với bên thứ ba mà không có sự đồng ý của bạn.',
              ),
              _buildSection(
                '6. Liên hệ',
                'Nếu bạn có câu hỏi hoặc thắc mắc về điều khoản sử dụng, vui lòng liên hệ:\n'
                    '\nEmail: support@runly.app',
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Cập nhật lần cuối: Tháng 4, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Điều khoản sử dụng\nRunly',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vui lòng đọc kỹ các điều khoản trước khi sử dụng ứng dụng.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
