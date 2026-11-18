import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../utils/feedback.dart';

/// Kartu kontak admin di halaman login: nomor teks + tombol salin.
///
/// Nomor berasal dari API (`/app-info`), bukan hardcode, supaya admin bisa
/// menggantinya kapan saja dari halaman pengaturan.
class AdminContactCard extends StatelessWidget {
  const AdminContactCard({super.key, required this.phone});

  final String phone;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: phone));

    if (!context.mounted) {
      return;
    }

    showAppSnackBar(
      context,
      'Nomor admin berhasil disalin.',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
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
                  'Butuh bantuan? Hubungi admin',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: AppTextStyles.bodyStrong.copyWith(letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
