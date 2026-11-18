import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/payment.dart';
import '../../models/registration.dart';
import '../../services/api_service.dart';
import '../../services/registration_service.dart';
import '../../utils/app_events.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/authenticated_image.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import '../ticket/ticket_screen.dart';

/// Halaman pembayaran event berbayar: nominal, QR, dan unggah bukti.
///
/// Tiket baru bisa dilihat setelah admin memverifikasi bukti pembayaran.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.registration});

  final Registration registration;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _imagePicker = ImagePicker();

  late Registration _registration;
  bool _isUploading = false;
  bool _isRefreshing = false;

  PaymentInfo get _payment => _registration.payment;
  bool get _isPaid => _registration.hasTicket;

  @override
  void initState() {
    super.initState();
    _registration = widget.registration;
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);

    try {
      final registration = await RegistrationService.getTicket(
        _registration.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _registration = registration;
        _isRefreshing = false;
      });

      showAppSnackBar(
        context,
        registration.payment.statusLabel,
        isSuccess: registration.hasTicket,
      );

      if (registration.hasTicket) {
        AppEvents.notifyDataChanged();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isRefreshing = false);
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  Future<void> _pickProof() async {
    XFile? picked;

    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'Tidak dapat membuka galeri. Coba lagi.',
        isError: true,
      );
      return;
    }

    if (picked == null || !mounted) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final registration = await RegistrationService.uploadPaymentProof(
        _registration.id,
        picked,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _registration = registration;
        _isUploading = false;
      });

      AppEvents.notifyDataChanged();
      showAppSnackBar(
        context,
        'Bukti pembayaran terkirim. Tunggu verifikasi admin ya.',
        isSuccess: true,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isUploading = false);
      showAppSnackBar(
        context,
        error.firstValidationError ?? error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isUploading = false);
      showAppSnackBar(
        context,
        'Gagal mengirim bukti pembayaran. Silakan coba lagi.',
        isError: true,
      );
    }
  }

  void _openTicket() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TicketScreen(registration: _registration),
      ),
    );
  }

  void _copyAccountNumber() {
    final number = _payment.accountNumber;

    if (number == null || number.isEmpty) {
      return;
    }

    Clipboard.setData(ClipboardData(text: number));
    showAppSnackBar(context, 'Nomor rekening disalin.', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final event = _registration.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPaid ? 'Pembayaran Lunas' : 'Pembayaran Tiket'),
        actions: [
          IconButton(
            tooltip: 'Cek status pembayaran',
            onPressed: _isRefreshing ? null : _refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusBanner(payment: _payment),
                  if (event != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(event.title, style: AppTextStyles.subtitle),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _AmountCard(payment: _payment),
                  if (!_isPaid) ...[
                    const SizedBox(height: AppSpacing.md),
                    _QrCard(payment: _payment),
                    const SizedBox(height: AppSpacing.md),
                    _AccountCard(payment: _payment, onCopy: _copyAccountNumber),
                    if (_payment.isRejected &&
                        (_payment.rejectionReason?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: AppSpacing.md),
                      _RejectionNote(reason: _payment.rejectionReason!),
                    ],
                    if (_payment.proofUrl != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ProofPreview(payment: _payment),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _payment.canUploadProof
                          ? (_payment.isRejected
                                ? 'UNGGAH ULANG BUKTI'
                                : 'UNGGAH BUKTI BAYAR')
                          : 'MENUNGGU VERIFIKASI ADMIN',
                      icon: Icons.upload_file_rounded,
                      isLoading: _isUploading,
                      onPressed: _payment.canUploadProof ? _pickProof : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PrimaryButton(
                      label: 'CEK STATUS PEMBAYARAN',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outlined,
                      isLoading: _isRefreshing,
                      onPressed: _isRefreshing ? null : _refresh,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _InfoNote(),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Pembayaran sudah diverifikasi admin. Tiket dan QR check-in kamu sudah aktif.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'LIHAT TIKET SAYA',
                      icon: Icons.qr_code_2_rounded,
                      onPressed: _openTicket,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color background;
    late final IconData icon;
    late final String message;

    if (payment.isPaid) {
      color = AppColors.success;
      background = AppColors.successSoft;
      icon = Icons.check_circle_rounded;
      message = 'Pembayaran kamu sudah lunas.';
    } else if (payment.isWaiting) {
      color = AppColors.warning;
      background = AppColors.warningSoft;
      icon = Icons.hourglass_top_rounded;
      message = 'Bukti pembayaran sedang diperiksa admin. Tiket terbit otomatis setelah disetujui.';
    } else if (payment.isRejected) {
      color = AppColors.error;
      background = AppColors.errorSoft;
      icon = Icons.cancel_rounded;
      message =
          'Bukti pembayaran ditolak. Silakan unggah ulang bukti yang benar.';
    } else {
      color = AppColors.warning;
      background = AppColors.warningSoft;
      icon = Icons.payments_outlined;
      message = 'Selesaikan pembayaran dulu ya. Tiket baru terbit setelah admin memverifikasi.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label: payment.statusLabel, color: color),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PEMBAYARAN',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.rupiah(payment.amount),
            style: AppTextStyles.display.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Transfer sesuai nominal, lalu unggah bukti pembayaran.',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    final qrUrl = payment.qrUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('QR Pembayaran', style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (qrUrl == null || qrUrl.isEmpty)
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Admin belum mengunggah QR pembayaran.\nHubungi panitia untuk info pembayaran.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(
                qrUrl,
                headers: ApiConfig.mediaHeaders,
                height: 240,
                width: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 190,
                  width: 240,
                  color: AppColors.fieldFill,
                  child: Center(
                    child: Text(
                      'QR gagal dimuat.\nPeriksa koneksi internet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }

                  return Container(
                    height: 240,
                    width: 240,
                    color: AppColors.fieldFill,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scan QR dengan aplikasi bank / e-wallet kamu.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.payment, required this.onCopy});

  final PaymentInfo payment;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final hasAccount =
        (payment.accountName?.isNotEmpty ?? false) ||
        (payment.accountNumber?.isNotEmpty ?? false);

    if (!hasAccount) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Rekening Tujuan', style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (payment.accountNumber != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nomor Rekening', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        payment.accountNumber!,
                        style: AppTextStyles.bodyStrong,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Salin nomor rekening',
                  onPressed: onCopy,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          if (payment.accountName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Atas Nama', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(payment.accountName!, style: AppTextStyles.bodyStrong),
          ],
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(payment.notes!, style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectionNote extends StatelessWidget {
  const _RejectionNote({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.report_gmailerrorred_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alasan penolakan',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPreview extends StatelessWidget {
  const _ProofPreview({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AuthenticatedImage(
              url: payment.proofUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorMessage: 'Bukti gagal dimuat.',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bukti pembayaran terkirim',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  payment.verifiedAt != null
                      ? 'Diperbarui ${Formatters.dateTime(payment.verifiedAt!.toIso8601String())}'
                      : 'Menunggu pemeriksaan admin',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tiket hanya terbit setelah admin memverifikasi bukti pembayaran. Simpan bukti transfer sampai tiket aktif.',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
