import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../data/local/isar_models.dart';
import '../health_schedules/schedule_provider.dart';

// Local state for the selected filter
final _selectedFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'All History',
);

class PetHistoryScreen extends ConsumerWidget {
  final Pet pet;

  const PetHistoryScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(
      petSchedulesProvider(pet.supabaseId ?? ''),
    );
    final selectedFilter = ref.watch(_selectedFilterProvider);

    // Filter Options
    final filters = [
      'All History',
      'Vaccine',
      'Medication',
      'Deworming',
      'Appointment',
    ];

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "${pet.name}'s History",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share functionality placeholder
            },
          ),
        ],
      ),
      body: schedulesAsync.when(
        data: (schedules) {
          // 1. Filter
          var history = schedules.where((s) => s.isCompleted).toList();

          if (selectedFilter != 'All History') {
            history = history
                .where(
                  (s) => s.type.toLowerCase() == selectedFilter.toLowerCase(),
                )
                .toList();
          }

          // 2. Sort (Newest First)
          history.sort(
            (a, b) =>
                b.completedAt?.compareTo(a.completedAt ?? DateTime(0)) ?? 0,
          );

          // 3. Group by Month
          final grouped = <String, List<HealthSchedule>>{};
          for (var item in history) {
            if (item.completedAt == null) continue;
            final key = DateFormat(
              'MMMM yyyy',
            ).format(item.completedAt!).toUpperCase();
            grouped.putIfAbsent(key, () => []).add(item);
          }

          // 4. Flatten List
          final flatItems = <Widget>[];
          grouped.forEach((month, items) {
            flatItems.add(_MonthHeader(month: month));
            for (int i = 0; i < items.length; i++) {
              flatItems.add(
                _HistoryItem(
                  item: items[i],
                  isLastInMonth: i == items.length - 1,
                ),
              );
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              final repo = ref.read(scheduleManagementProvider);
              await repo.syncAllUnsynced();
              await repo.fetchSchedulesFromRemote();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Pet Info Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                            image: pet.photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(pet.photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: theme.colorScheme.surface,
                          ),
                          child: pet.photoUrl == null
                              ? Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.name,
                                style: GoogleFonts.manrope(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 14,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pet.breed ?? pet.species,
                                    style: GoogleFonts.manrope(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (pet.weightKg != null) ...[
                                    Icon(
                                      Icons.scale,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pet.weightKg}kg',
                                      style: GoogleFonts.manrope(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Age badge (approx)
                        if (pet.birthDate != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _calculateAge(pet.birthDate!),
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Filters
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isSelected = selectedFilter == filter;
                        return ChoiceChip(
                          label: Text(filter),
                          avatar: Icon(
                            _getCategoryIcon(filter),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : _getCategoryColor(filter),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(_selectedFilterProvider.notifier).state =
                                  filter;
                            }
                          },
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: GoogleFonts.manrope(
                            color: isSelected
                                ? Colors.black
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.1,
                                    ),
                            ),
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Timeline List
                if (history.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No records found",
                            style: GoogleFonts.manrope(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => flatItems[index],
                      childCount: flatItems.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final ageDays = now.difference(birthDate).inDays;
    final ageYears = ageDays ~/ 365;
    if (ageYears > 0) return '${ageYears}Y';
    final ageMonths = ageDays ~/ 30;
    if (ageMonths > 0) return '${ageMonths}M';
    return '${ageDays}D';
  }

  static Color _getCategoryColor(String type) {
    if (type == 'All History') return const Color(0xFF2D6A4F);
    switch (type.toLowerCase()) {
      case 'vaccine':
        return const Color(0xFF00B894); // Green
      case 'medication':
        return const Color(0xFFFF7675); // Red/Pink
      case 'deworming':
        return const Color(0xFFA29BFE); // Purple
      case 'appointment':
        return const Color(0xFF0984E3); // Blue
      default:
        return const Color(0xFFE17055); // Orange
    }
  }

  static IconData _getCategoryIcon(String type) {
    if (type == 'All History') return Icons.history;
    switch (type.toLowerCase()) {
      case 'vaccine':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'deworming':
        return Icons.bug_report;
      case 'appointment':
        return Icons.local_hospital;
      default:
        return Icons.pets;
    }
  }
}

class _MonthHeader extends StatelessWidget {
  final String month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Line Logic
            SizedBox(
              width: 40,
              child: Center(
                child: Container(
                  width: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                month,
                style: GoogleFonts.manrope(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final HealthSchedule item;
  final bool isLastInMonth;

  const _HistoryItem({required this.item, required this.isLastInMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PetHistoryScreen._getCategoryColor(item.type);
    final icon = PetHistoryScreen._getCategoryIcon(item.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Line & Icon
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (item.completedAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('MMM d').format(item.completedAt!),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.notes ?? item.type.toUpperCase(),
                        style: GoogleFonts.manrope(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.type.toLowerCase() == 'vaccine') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Vet Clinic",
                              style: GoogleFonts.manrope(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
