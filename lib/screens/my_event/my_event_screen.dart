import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/registration.dart';
import '../../services/api_service.dart';
import '../../services/registration_service.dart';
import '../../utils/app_events.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/event_banner.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import '../payment/payment_screen.dart';
import '../ticket/ticket_screen.dart';

class MyEventScreen extends StatefulWidget {
  const MyEventScreen({super.key});

  @override
  State<MyEventScreen> createState() => _MyEventScreenState();
}

class _MyEventScreenState extends State<MyEventScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AppEvents.dataVersion.addListener(_handleDataChanged);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_handleDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleDataChanged() {
    if (mounted) {
      setState(() => _refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Event'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _RegistrationList(
              key: ValueKey('upcoming-$_refreshKey'),
              status: 'upcoming',
              emptyTitle: 'Kamu belum mengikuti event apa pun.',
              emptyMessage: 'Yuk cari event menarik di halaman Explore.',
              emptyIcon: Icons.event_available_outlined,
            ),
            _RegistrationList(
              key: ValueKey('past-$_refreshKey'),
              status: 'past',
              emptyTitle: 'Belum ada riwayat event.',
              emptyMessage: 'Event yang sudah selesai akan muncul di sini.',
              emptyIcon: Icons.history_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationList extends StatefulWidget {
  const _RegistrationList({
    super.key,
    required this.status,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final String status;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  State<_RegistrationList> createState() => _RegistrationListState();
}

class _RegistrationListState extends State<_RegistrationList> {
  List<Registration> _registrations = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations = await RegistrationService.myRegistrations(
        status: widget.status,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _registrations = registrations;
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

  void _openTicket(Registration registration) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => registration.hasTicket
            ? TicketScreen(registration: registration)
            : PaymentScreen(registration: registration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _registrations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: const [EventListSkeleton(itemCount: 4, imageSize: 64)],
      );
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _registrations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  title: widget.emptyTitle,
                  message: widget.emptyMessage,
                  icon: widget.emptyIcon,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: _registrations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final registration = _registrations[index];

                return FadeSlideIn(
                  index: index,
                  child: _RegistrationCard(
                    registration: registration,
                    onTap: () => _openTicket(registration),
                  ),
                );
              },
            ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration, required this.onTap});

  final Registration registration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final event = registration.event;

    return PressScale(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: EventBanner(
                          imageUrl: event?.bannerUrl,
                          categoryName: event?.categoryName,
                          height: 64,
                          iconSize: 24,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event?.title ?? 'Event',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle.copyWith(
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    Formatters.shortDate(event?.date),
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    event?.location ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: registration.isAttended
                            ? 'Hadir'
                            : event?.isFinished ?? false
                            ? 'Selesai'
                            : event?.isRegistrationClosed ?? false
                            ? 'Waktu pendaftaran habis'
                            : 'Terdaftar',
                        color: registration.isAttended
                            ? AppColors.success
                            : event?.isFinished ?? false
                            ? AppColors.textSecondary
                            : event?.isRegistrationClosed ?? false
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        registration.hasTicket
                            ? Icons.confirmation_number_outlined
                            : Icons.payments_outlined,
                        size: 15,
                        color: registration.hasTicket
                            ? AppColors.textMuted
                            : _paymentColor(registration),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          registration.hasTicket
                              ? registration.ticketCode!
                              : registration.payment.statusLabel,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: registration.hasTicket ? 0.8 : 0,
                            color: registration.hasTicket
                                ? AppColors.textSecondary
                                : _paymentColor(registration),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          registration.hasTicket ? 'Lihat Tiket' : 'Bayar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _paymentColor(Registration registration) {
    switch (registration.payment.status) {
      case 'paid':
        return AppColors.success;
      case 'waiting_confirmation':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
