import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/payment.dart';
import '../../models/registration.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_events.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/authenticated_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'admin_payment_setting_screen.dart';

/// Daftar pembayaran event berbayar + verifikasi bukti bayar.
class AdminPaymentListScreen extends StatefulWidget {
  const AdminPaymentListScreen({super.key});

  @override
  State<AdminPaymentListScreen> createState() => _AdminPaymentListScreenState();
}

class _AdminPaymentListScreenState extends State<AdminPaymentListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _status = '';
  List<Registration> _payments = const [];
  PaymentSummary _summary = const PaymentSummary();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentService.getPayments(
        status: _status,
        query: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = result.payments;
        _summary = result.summary;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _selectStatus(String status) {
    if (_status == status) {
      return;
    }

    setState(() => _status = status);
    _load();
  }

  Future<void> _openDetail(Registration registration) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _PaymentDetailSheet(registration: registration),
    );

    if (changed == true) {
      AppEvents.notifyDataChanged();
      _load();
    }
  }

  Future<void> _openSetting() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminPaymentSettingScreen(),
      ),
    );

    AppEvents.notifyDataChanged();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan QR & rekening',
            onPressed: _openSetting,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _SummaryRow(
                summary: _summary,
                selected: _status,
                onSelected: _selectStatus,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Cari nama, NIM, atau event...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Memuat data pembayaran...');
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }

    if (_payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            EmptyState(
              title: _searchController.text.trim().isEmpty
                  ? 'Belum ada pembayaran.'
                  : 'Pembayaran tidak ditemukan.',
              message: _searchController.text.trim().isEmpty
                  ? 'Peserta event berbayar akan muncul di sini.'
                  : 'Coba kata kunci atau filter lain.',
              icon: Icons.payments_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: _payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final registration = _payments[index];

          return _PaymentCard(
            registration: registration,
            onTap: () => _openDetail(registration),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.summary,
    required this.selected,
    required this.onSelected,
  });

  final PaymentSummary summary;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <({String value, String label, int count, Color color})>[
      (
        value: '',
        label: 'Semua',
        count: summary.total,
        color: AppColors.primary,
      ),
      (
        value: 'waiting_confirmation',
        label: 'Menunggu',
        count: summary.waiting,
        color: AppColors.warning,
      ),
      (
        value: 'unpaid',
        label: 'Belum Bayar',
        count: summary.unpaid,
        color: AppColors.textSecondary,
      ),
      (
        value: 'paid',
        label: 'Lunas',
        count: summary.paid,
        color: AppColors.success,
      ),
      (
        value: 'rejected',
        label: 'Ditolak',
        count: summary.rejected,
        color: AppColors.error,
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selected == item.value;

          return ChoiceChip(
            label: Text('${item.label} ${item.count}'),
            selected: isSelected,
            onSelected: (_) => onSelected(item.value),
            selectedColor: item.color,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.registration, required this.onTap});

  final Registration registration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = registration.user;
    final event = registration.event;
    final payment = registration.payment;
    final participantName =
        registration.participantName ?? user?.name ?? 'Peserta';
    final participantNim = registration.participantNim ?? user?.nim ?? '-';
    final participantEmail =
        registration.participantEmail ?? user?.email ?? '-';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(participantName, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          '$participantNim • $participantEmail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: payment.statusLabel,
                    color: _paymentColor(payment.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event?.title ?? 'Event',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    Formatters.rupiah(payment.amount),
                    style: AppTextStyles.subtitle,
                  ),
                  const Spacer(),
                  Text(
                    'Lihat bukti',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailSheet extends StatefulWidget {
  const _PaymentDetailSheet({required this.registration});

  final Registration registration;

  @override
  State<_PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends State<_PaymentDetailSheet> {
  bool _isSubmitting = false;

  Registration get _registration => widget.registration;
  PaymentInfo get _payment => _registration.payment;

  Future<void> _verify() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Verifikasi Pembayaran',
      message:
          'Setujui pembayaran ${_registration.user?.name ?? 'peserta'}? Tiket akan langsung terbit dan bisa dipakai check-in.',
      confirmLabel: 'Ya, verifikasi',
    );

    if (!confirmed) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await PaymentService.verify(_registration.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      showAppSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      showAppSnackBar(
        context,
        'Gagal memverifikasi pembayaran. Coba lagi.',
        isError: true,
      );
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tolak Pembayaran', style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Peserta akan melihat alasan ini dan bisa mengunggah bukti baru.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLength: 200,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Nominal transfer belum sesuai.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final text = reasonController.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.of(context).pop(text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await PaymentService.reject(_registration.id, reason);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      showAppSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      showAppSnackBar(
        context,
        'Gagal menolak pembayaran. Coba lagi.',
        isError: true,
      );
    }
  }

  void _openProof() {
    final url = _payment.proofUrl;

    if (url == null || url.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: AuthenticatedImage(
                    url: url,
                    fit: BoxFit.contain,
                    errorMessage: 'Bukti pembayaran gagal dimuat.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _registration.user;
    final event = _registration.event;
    final participantName =
        _registration.participantName ?? user?.name ?? 'Peserta';
    final participantNim = _registration.participantNim ?? user?.nim ?? '-';
    final participantEmail =
        _registration.participantEmail ?? user?.email ?? '-';
    final canVerify = _payment.status == 'waiting_confirmation';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(participantName, style: AppTextStyles.title),
                  ),
                  StatusBadge(
                    label: _payment.statusLabel,
                    color: _paymentColor(_payment.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$participantNim • $participantEmail',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _DetailLine(label: 'Event', value: event?.title ?? '-'),
                    const SizedBox(height: 8),
                    _DetailLine(
                      label: 'Nominal',
                      value: Formatters.rupiah(_payment.amount),
                    ),
                    const SizedBox(height: 8),
                    _DetailLine(
                      label: 'Tanggal Daftar',
                      value: Formatters.dateTime(
                        _registration.registeredAt?.toIso8601String(),
                      ),
                    ),
                    if (_registration.ticketCode != null) ...[
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Kode Tiket',
                        value: _registration.ticketCode!,
                      ),
                    ],
                  ],
                ),
              ),
              if (_payment.rejectionReason != null &&
                  _payment.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Alasan penolakan sebelumnya: ${_payment.rejectionReason}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Bukti Pembayaran', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.sm),
              if (_payment.proofUrl == null)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      'Peserta belum mengunggah bukti pembayaran.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _openProof,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      children: [
                        AuthenticatedImage(
                          url: _payment.proofUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorMessage: 'Bukti gagal dimuat.',
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Perbesar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              if (canVerify) ...[
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _verify,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('VERIFIKASI PEMBAYARAN'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _reject,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('TOLAK PEMBAYARAN'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.errorSoft),
                  ),
                ),
              ] else
                Text(
                  _payment.statusLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: AppTextStyles.caption)),
        Expanded(child: Text(value, style: AppTextStyles.bodyStrong)),
      ],
    );
  }
}

Color _paymentColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'waiting_confirmation':
      return AppColors.warning;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}
