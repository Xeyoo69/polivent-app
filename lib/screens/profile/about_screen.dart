import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/section_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang PoliVent')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AppLogo(size: 60, center: true)),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apa itu PoliVent?', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'PoliVent adalah aplikasi mobile yang membantu mahasiswa Politeknik Negeri Lampung menemukan, mendaftar, dan menghadiri event kampus dengan mudah. Setiap pendaftaran menghasilkan tiket digital berisi QR Code.',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Fitur Utama'),
                  const SizedBox(height: AppSpacing.md),
                  const _FeatureTile(
                    icon: Icons.search_rounded,
                    title: 'Temukan Event',
                    description:
                        'Cari seminar, workshop, webinar, lomba, dan kegiatan kampus lainnya.',
                  ),
                  const _FeatureTile(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Daftar Online',
                    description:
                        'Pendaftaran cepat dengan validasi kuota dan status event.',
                  ),
                  const _FeatureTile(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Tiket Digital',
                    description:
                        'Tiket dengan QR Code yang bisa ditunjukkan langsung ke panitia.',
                  ),
                  const _FeatureTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Event',
                    description:
                        'Pengelola event dapat mengatur event dan melihat daftar peserta.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temukan. Daftar. Hadiri.',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project Mata Kuliah Pemrograman Aplikasi Mobile\nPoliteknik Negeri Lampung • 2026',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      'Versi 1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
