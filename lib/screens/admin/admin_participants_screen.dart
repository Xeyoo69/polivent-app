import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/api_service.dart';
import '../../services/event_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

class AdminParticipantsScreen extends StatefulWidget {
  const AdminParticipantsScreen({super.key, required this.event});

  final Event event;

  @override
  State<AdminParticipantsScreen> createState() =>
      _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  late Event _event;
  List<Registration> _participants = const [];
  int _total = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
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
      final result = await EventService.getParticipants(
        widget.event.id,
        query: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _event = result.event ?? _event;
        _participants = result.participants;
        _total = result.total;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peserta Event')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _EventSummary(event: _event, total: _total),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Cari nama, NIM, atau kode tiket...',
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
      return const LoadingWidget(message: 'Memuat peserta...');
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }

    if (_participants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            EmptyState(
              title: _searchController.text.trim().isEmpty
                  ? 'Belum ada peserta.'
                  : 'Peserta tidak ditemukan.',
              message: _searchController.text.trim().isEmpty
                  ? 'Peserta yang mendaftar akan muncul di sini.'
                  : 'Coba kata kunci lain.',
              icon: Icons.person_search_rounded,
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
        itemCount: _participants.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          return _ParticipantCard(registration: _participants[index]);
        },
      ),
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.event, required this.total});

  final Event event;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = event.quota <= 0
        ? 0.0
        : (total / event.quota).clamp(0.0, 1.0);

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
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            '${Formatters.shortDate(event.date)} • ${Formatters.timeRange(event.startTime, event.endTime)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text('$total peserta terdaftar', style: AppTextStyles.bodyStrong),
              const Spacer(),
              Text('Kuota ${event.quota}', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({required this.registration});

  final Registration registration;

  @override
  Widget build(BuildContext context) {
    final user = registration.user;
    final participantName =
        registration.participantName ?? user?.name ?? 'Peserta';
    final participantNim = registration.participantNim ?? user?.nim ?? '-';
    final participantEmail =
        registration.participantEmail ?? user?.email ?? '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: registration.statusLabel,
                    color: registration.isAttended
                        ? AppColors.success
                        : registration.isCancelled
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  if (registration.payment.required) ...[
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: registration.payment.statusLabel,
                      color: _paymentColor(registration),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (registration.teamName != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tim: ${registration.teamName}',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (
              var index = 0;
              index < registration.teamMembers.length;
              index++
            )
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${index + 1}. ${registration.teamMembers[index]['name'] ?? '-'} • NIM ${registration.teamMembers[index]['nim'] ?? '-'}',
                  style: AppTextStyles.caption,
                ),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                registration.hasTicket
                    ? Icons.confirmation_number_outlined
                    : Icons.payments_outlined,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                registration.ticketCode ?? registration.payment.statusLabel,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: registration.hasTicket ? 0.8 : 0,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.dateTime(
                  registration.registeredAt?.toIso8601String(),
                ),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
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
        return AppColors.textSecondary;
    }
  }
}
