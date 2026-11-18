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
import '../../widgets/section_header.dart';
import 'admin_event_form_screen.dart';
import 'admin_participants_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.onManageEvents,
    this.onManagePayments,
  });

  final VoidCallback? onManageEvents;
  final VoidCallback? onManagePayments;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats _stats = const AdminStats();
  List<Event> _upcomingEvents = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppEvents.dataVersion.addListener(_handleDataChanged);
    _load();
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_handleDataChanged);
    super.dispose();
  }

  void _handleDataChanged() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        EventService.getStats(),
        EventService.getEvents(status: 'upcoming', perPage: 3),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = results[0] as AdminStats;
        _upcomingEvents = (results[1] as EventPage).events;
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

  Future<void> _openForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AdminEventFormScreen()),
    );

    if (saved == true) {
      AppEvents.notifyDataChanged();
    }
  }

  void _openParticipants(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminParticipantsScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'POLIVENT ADMIN',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Text('Dashboard', style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(
              'Halo ${user?.name ?? 'Admin'}, kelola event kampus di sini.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoading)
              const SizedBox(
                height: 260,
                child: LoadingWidget(message: 'Memuat statistik...'),
              )
            else if (_errorMessage != null)
              SizedBox(
                height: 300,
                child: ErrorState(message: _errorMessage!, onRetry: _load),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    label: 'Total Event',
                    value: '${_stats.totalEvents}',
                    icon: Icons.event_rounded,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Pendaftaran Aktif',
                    value: '${_stats.activeEvents}',
                    icon: Icons.play_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'Total Peserta',
                    value: '${_stats.totalParticipants}',
                    icon: Icons.groups_rounded,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Event Selesai',
                    value: '${_stats.finishedEvents}',
                    icon: Icons.done_all_rounded,
                    color: AppColors.textSecondary,
                  ),
                  _StatCard(
                    label: 'Menunggu Verifikasi',
                    value: '${_stats.pendingPayments}',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    label: 'Pendapatan Tiket',
                    value: Formatters.rupiah(_stats.revenue),
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Tambah Event',
                      icon: Icons.add_rounded,
                      onPressed: _openForm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Kelola Event',
                      icon: Icons.tune_rounded,
                      variant: AppButtonVariant.outlined,
                      onPressed: widget.onManageEvents,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _stats.pendingPayments > 0
                    ? 'VERIFIKASI PEMBAYARAN (${_stats.pendingPayments})'
                    : 'VERIFIKASI PEMBAYARAN',
                icon: Icons.fact_check_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: widget.onManagePayments,
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Event Mendatang',
                actionLabel: 'Lihat semua',
                onAction: widget.onManageEvents,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_upcomingEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Belum ada event mendatang. Tambahkan event baru untuk memulai.',
                    style: AppTextStyles.body,
                  ),
                )
              else
                for (final event in _upcomingEvents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _UpcomingEventTile(
                      event: event,
                      onTap: () => _openParticipants(event),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline.copyWith(
                  fontSize: value.length > 8 ? 16 : 22,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: EventBanner(
                  imageUrl: event.bannerUrl,
                  categoryName: event.categoryName,
                  height: 56,
                  iconSize: 22,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Formatters.shortDate(event.date)} • ${event.participantsCount}/${event.quota} peserta',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
