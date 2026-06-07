import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/repositories/group_repository.dart';
import '../bloc/group_list_bloc.dart';

/// QR Scanner page for joining groups by scanning QR codes
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'group.qr_title'.tr(),
          style: AppTextStyles.heading4.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Pick QR from gallery
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: 'Chọn từ thư viện',
            onPressed: _isProcessing ? null : _pickFromGallery,
          ),
          // Toggle flash
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Switch camera
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scan area
          _ScanOverlay(),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'group.qr_title'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'group.joining'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) return;

    final result = await _controller.analyzeImage(picked.path);
    if (result == null || result.barcodes.isEmpty) {
      if (mounted) _showError('Không tìm thấy mã QR trong ảnh');
      return;
    }
    _onDetect(result);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    // Parse QR data: walktogether://group/join/{groupId}
    final uri = Uri.tryParse(rawValue);
    if (uri == null ||
        uri.scheme != 'walktogether' ||
        uri.host != 'group' ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments[0] != 'join') {
      _showError('Mã QR không hợp lệ. Vui lòng quét lại');
      return;
    }

    final groupId = uri.pathSegments[1];
    if (groupId.isEmpty) {
      _showError('Không tìm thấy ID nhóm trong mã QR');
      return;
    }

    _joinGroup(groupId);
  }

  Future<void> _joinGroup(String groupId) async {
    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final repository = context.read<GroupRepository>();
      await repository.joinByQR(groupId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('group.joined_success'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh group list and navigate to group detail
      context.read<GroupListBloc>().add(GroupListLoadRequested());
      context.push('/groups/$groupId');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);
      _controller.start();

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already') || errorMsg.contains('member')) {
        // Already a member — navigate to group instead of showing error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn đã tham gia nhóm này rồi'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        context.read<GroupListBloc>().add(GroupListLoadRequested());
        context.push('/groups/$groupId');
      } else if (errorMsg.contains('not found')) {
        _showError('Nhóm không tồn tại');
      } else {
        _showError('Không thể tham gia nhóm. Vui lòng thử lại');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// === Scan area overlay ===
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.red, // color doesn't matter, it's cut out
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
