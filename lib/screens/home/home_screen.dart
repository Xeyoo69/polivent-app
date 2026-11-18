import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_events.dart';
import '../../utils/category_style.dart';
import '../../utils/formatters.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/decorative_pattern.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/event_card.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../event/event_detail_screen.dart';
import '../explore/explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Event> _events = const [];
  List<Category> _categories = const [];
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
        EventService.getEvents(status: 'upcoming', perPage: 10),
        EventService.getCategories(),
      ]);

      if (!mounted) {
        return;
      }

      final page = results[0] as EventPage;
      final categories = results[1] as List<Category>;

      setState(() {
        _events = page.events;
        _categories = categories;
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

  void _openEvent(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(eventId: event.id, initialEvent: event),
      ),
    );
  }

  void _openExplore({String? query, int? categoryId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreScreen(
          initialQuery: query,
          initialCategoryId: categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final firstName = (user?.name ?? 'Mahasiswa').split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            _HomeHeader(
              firstName: firstName,
              initials: user?.initials ?? 'M',
              dateLabel: Formatters.fullDate(DateTime.now()),
              eventCount: _isLoading ? null : _events.length,
              onOpenProfile: widget.onOpenProfile,
              onSearchTap: () => _openExplore(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _events.isEmpty) {
      return const EventListSkeleton(itemCount: 4);
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 320,
        child: ErrorState(
          message: _errorMessage!,
          onRetry: _load,
        ),
      );
    }

    if (_events.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          title: 'Belum ada event tersedia.',
          message: 'Event baru akan muncul di sini.',
          icon: Icons.event_busy_rounded,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Event Pilihan',
          actionLabel: 'Lihat semua',
          onAction: () => _openExplore(),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 4),
            itemCount: _events.take(5).length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final event = _events[index];

              return FadeSlideIn(
                index: index,
                child: FeaturedEventCard(
                  event: event,
                  onTap: () => _openEvent(event),
                ),
              );
            },
          ),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Kategori'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];

                return CategoryChip(
                  label: category.name,
                  selected: false,
                  icon: CategoryStyle.forName(category.name).icon,
                  onTap: () => _openExplore(categoryId: category.id),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(
          title: 'Event Terbaru',
          actionLabel: 'Lihat semua',
          onAction: () => _openExplore(),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < _events.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FadeSlideIn(
              index: index,
              child: EventCard(
                event: _events[index],
                onTap: () => _openEvent(_events[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.initials,
    required this.dateLabel,
    required this.eventCount,
    required this.onOpenProfile,
    required this.onSearchTap,
  });

  final String firstName;
  final String initials;
  final String dateLabel;
  final int? eventCount;
  final VoidCallback? onOpenProfile;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.header,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecorativePattern(opacity: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $firstName 👋',
                              style: AppTextStyles.headline.copyWith(
                                color: Colors.white,
                                fontSize: 23,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Temukan event menarik di Polinela.',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PressScale(
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: CircleBorder(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.32),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onOpenProfile,
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              eventCount == null
                                  ? 'Memuat...'
                                  : '$eventCount event',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SearchBar(onTap: onSearchTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari seminar, workshop, lomba...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
