import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_events.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'admin_event_form_screen.dart';
import 'admin_participants_screen.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Event> _events = const [];
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
    _debounce?.cancel();
    _searchController.dispose();
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
      final page = await EventService.getEvents(
        query: _searchController.text,
        perPage: 50,
      );

      final events = [...page.events]
        ..sort((a, b) {
          final dateA = a.date ?? DateTime(2000);
          final dateB = b.date ?? DateTime(2000);

          return dateB.compareTo(dateA);
        });

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
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

  Future<void> _openForm({Event? event}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminEventFormScreen(event: event),
      ),
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

  Future<void> _delete(Event event) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus event?',
      message:
          'Apakah Anda yakin ingin menghapus "${event.title}"? Semua pendaftaran pada event ini juga akan terhapus.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await EventService.deleteEvent(event.id);

      if (!mounted) {
        return;
      }

      showAppSnackBar(context, 'Event berhasil dihapus.', isSuccess: true);
      AppEvents.notifyDataChanged();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'Terjadi kesalahan. Silakan coba lagi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Event')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Cari judul event...',
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
      return const LoadingWidget(message: 'Memuat event...');
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            EmptyState(
              title: 'Belum ada event.',
              message: 'Tekan tombol Tambah untuk membuat event pertama.',
              icon: Icons.event_busy_rounded,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: _events.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final event = _events[index];

          return _AdminEventCard(
            event: event,
            onEdit: () => _openForm(event: event),
            onDelete: () => _delete(event),
            onParticipants: () => _openParticipants(event),
          );
        },
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  const _AdminEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onParticipants,
  });

  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onParticipants;

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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.subtitle.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.categoryName} • ${Formatters.shortDate(event.date)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: event.isFinished
                    ? 'Selesai'
                    : event.isRegistrationClosed
                    ? 'Waktu pendaftaran habis'
                    : event.isFull
                    ? 'Penuh'
                    : 'Aktif',
                color: event.isFinished
                    ? AppColors.textSecondary
                    : event.isRegistrationClosed
                    ? AppColors.warning
                    : event.isFull
                    ? AppColors.error
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${event.participantsCount} peserta • kuota ${event.quota} • ${event.priceLabel}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.timeRange(event.startTime, event.endTime),
            style: AppTextStyles.caption,
          ),
          const Divider(height: 24),
          Row(
            children: [
              TextButton.icon(
                onPressed: onParticipants,
                icon: const Icon(Icons.groups_outlined, size: 17),
                label: const Text('Peserta'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
                tooltip: 'Edit event',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.error,
                tooltip: 'Hapus event',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
