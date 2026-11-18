import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_events.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_state.dart';
import '../../widgets/event_banner.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'registration_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  final int eventId;
  final Event? initialEvent;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    _isLoading = _event == null;
    _load();
  }

  Future<void> _load() async {
    if (_event == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final event = await EventService.getEvent(widget.eventId);

      if (!mounted) {
        return;
      }

      setState(() {
        _event = event;
        _isLoading = false;
        _errorMessage = null;
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

  Future<void> _openRegistration() async {
    final event = _event;

    if (event == null) {
      return;
    }

    if (!AuthService.instance.isLoggedIn) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => RegistrationScreen(event: event)),
    );

    if (!mounted) {
      return;
    }

    // Muat ulang apa pun hasilnya: jika user sampai ke tiket lalu kembali,
    // status "sudah terdaftar" harus langsung terlihat.
    AppEvents.notifyDataChanged();
    await _load();

    if (result == true && mounted) {
      AppEvents.notifyDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: AppColors.surface,
            elevation: 3,
            shadowColor: const Color(0x330F172A),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              tooltip: 'Kembali',
            ),
          ),
        ),
      ),
      body: _buildBody(event),
      bottomNavigationBar: event == null ? null : _buildBottomBar(event),
    );
  }

  Widget _buildBody(Event? event) {
    if (_isLoading && event == null) {
      return const LoadingWidget(message: 'Memuat detail event...');
    }

    if (event == null) {
      return ErrorState(
        message: _errorMessage ?? 'Terjadi kesalahan. Silakan coba lagi.',
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                EventBanner(
                  imageUrl: event.bannerUrl,
                  categoryName: event.categoryName,
                  height: 280,
                  iconSize: 54,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            event.categoryName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (event.isFinished)
                          const StatusBadge(
                            label: 'Selesai',
                            color: AppColors.textSecondary,
                          )
                        else if (event.isRegistrationClosed)
                          const StatusBadge(
                            label: 'Waktu pendaftaran habis',
                            color: AppColors.warning,
                          )
                        else if (event.isFull)
                          const StatusBadge(
                            label: 'Kuota Penuh',
                            color: AppColors.error,
                          )
                        else
                          StatusBadge(
                            label: Formatters.relative(event.date),
                            color: AppColors.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(event.title, style: AppTextStyles.headline),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.organizer,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _InfoCard(event: event),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Deskripsi', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.description.isEmpty ? '-' : event.description,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _QuotaSection(event: event),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tiket digital dengan QR Code akan dibuat otomatis setelah kamu mendaftar. Tunjukkan tiket saat acara berlangsung.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Event event) {
    final String label;
    final VoidCallback? onPressed;

    if (event.isRegistered) {
      label = 'SUDAH TERDAFTAR';
      onPressed = null;
    } else if (event.isFinished) {
      label = 'EVENT SELESAI';
      onPressed = null;
    } else if (event.isRegistrationClosed) {
      label = 'WAKTU PENDAFTARAN HABIS';
      onPressed = null;
    } else if (event.isFull) {
      label = 'KUOTA PENUH';
      onPressed = null;
    } else {
      label = event.isPaidEvent
          ? 'DAFTAR - ${event.priceLabel}'
          : 'DAFTAR SEKARANG';
      onPressed = _openRegistration;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: label,
          onPressed: onPressed,
          icon: onPressed == null ? null : Icons.how_to_reg_rounded,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal',
            value: Formatters.fullDate(event.date),
          ),
          if (event.registrationDeadlineDate != null &&
              event.registrationDeadlineTime != null) ...[
            const Divider(height: 22),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: 'Terakhir Daftar',
              value:
                  '${Formatters.fullDate(event.registrationDeadlineDate)} • ${Formatters.time(event.registrationDeadlineTime)} WIB',
            ),
          ],
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Waktu',
            value: Formatters.timeRange(event.startTime, event.endTime),
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Lokasi',
            value: event.location,
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'Peserta',
            value: '${event.participantsCount} peserta terdaftar',
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Harga Tiket',
            value: event.priceLabel,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyStrong),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotaSection extends StatelessWidget {
  const _QuotaSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final ratio = event.quota <= 0
        ? 0.0
        : (event.participantsCount / event.quota).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kuota Peserta', style: AppTextStyles.subtitle),
            Text(
              '${event.participantsCount}/${event.quota}',
              style: AppTextStyles.bodyStrong,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: ratio),
          duration: AppMotion.slow,
          curve: AppMotion.emphasized,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  event.isFull ? AppColors.error : AppColors.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.quotaLabel,
          style: AppTextStyles.caption.copyWith(
            color: event.isFull ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
