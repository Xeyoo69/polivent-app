import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/event_service.dart';
import '../../utils/category_style.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/event_card.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/skeleton.dart';
import '../event/event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
  });

  final String? initialQuery;
  final int? initialCategoryId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Event> _events = const [];
  List<Category> _categories = const [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedCategoryId = widget.initialCategoryId;
    _loadCategories();
    _loadEvents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await EventService.getCategories();

      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (_) {
      // Kategori bukan data kritis; list event tetap bisa tampil.
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await EventService.getEvents(
        query: _searchController.text,
        categoryId: _selectedCategoryId,
        status: 'upcoming',
        perPage: 50,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _events = page.events;
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
    _debounce = Timer(const Duration(milliseconds: 400), _loadEvents);
  }

  void _selectCategory(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadEvents();
  }

  void _openEvent(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(eventId: event.id, initialEvent: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadEvents(),
                style: AppTextStyles.bodyStrong.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari event, penyelenggara, atau lokasi...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _loadEvents();
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          tooltip: 'Hapus pencarian',
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CategoryChip(
                      label: 'Semua',
                      selected: _selectedCategoryId == null,
                      icon: Icons.apps_rounded,
                      onTap: () => _selectCategory(null),
                    );
                  }

                  final category = _categories[index - 1];

                  return CategoryChip(
                    label: category.name,
                    selected: _selectedCategoryId == category.id,
                    icon: CategoryStyle.forName(category.name).icon,
                    onTap: () => _selectCategory(category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: const [EventListSkeleton(itemCount: 5)],
      );
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _loadEvents);
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            EmptyState(
              title: 'Event tidak ditemukan.',
              message: 'Coba kata kunci lain atau ubah filter kategori.',
              icon: Icons.search_off_rounded,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: _events.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: Text(
                  '${_events.length} event ditemukan',
                  style: AppTextStyles.caption,
                ),
              ),
            );
          }

          final event = _events[index];

          return FadeSlideIn(
            index: index,
            child: EventCard(
              event: event,
              onTap: () => _openEvent(event),
            ),
          );
        },
      ),
    );
  }
}

