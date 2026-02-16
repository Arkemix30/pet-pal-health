import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/local/isar_models.dart';
import '../health_schedules/pet_details_screen.dart';
import '../health_schedules/schedule_provider.dart';
import 'pet_provider.dart';
import 'pet_form_screen.dart';
import '../health_schedules/add_schedule_screen.dart';
import '../../core/theme/app_theme.dart';

final activePetIdProvider = StateProvider<String?>((ref) => null);

class PetDashboardScreen extends ConsumerWidget {
  const PetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsStreamProvider);
    final theme = Theme.of(context);
    final activePetId = ref.watch(activePetIdProvider);

    // Initial sync on app load
    ref.listen(petManagementProvider, (previous, next) {
      next.performFullSync();
      final schedMgr = ref.read(scheduleManagementProvider);
      schedMgr.syncAllUnsynced();
      schedMgr.fetchSchedulesFromRemote();
    });

    return Scaffold(
      body: petsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return _buildEmptyState(context);
          }

          // Ensure an active pet is selected
          final activePet = pets.firstWhere(
            (p) => p.supabaseId == activePetId,
            orElse: () => pets.first,
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context, pets, activePet, ref),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildFeaturedCard(context, activePet),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Upcoming Reminders'),
                      const SizedBox(height: 16),
                      _buildUpcomingTimeline(context, activePet),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, activePet),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PetFormScreen())),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Pet> pets,
    Pet activePet,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 220,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isCollapsed = constraints.maxHeight < 200;
          return FlexibleSpaceBar(
            background: Container(
              padding: EdgeInsets.only(
                top: isCollapsed ? 80 : 60,
                left: 20,
                right: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dashboard',
                          style: GoogleFonts.manrope(
                            fontSize: isCollapsed ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_none,
                                color: theme.colorScheme.onSurface,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.sync,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(petManagementProvider)
                                    .performFullSync();
                                final schedMgr = ref.read(
                                  scheduleManagementProvider,
                                );
                                await schedMgr.syncAllUnsynced();
                                await schedMgr.fetchSchedulesFromRemote();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCollapsed ? 12 : 20),
                  SizedBox(
                    height: isCollapsed ? 60 : 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: pets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == pets.length) {
                          return _buildAddPetButton(context);
                        }

                        final pet = pets[index];
                        final isActive = pet.supabaseId == activePet.supabaseId;
                        return _buildPetAvatarItem(context, pet, isActive, ref);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetAvatarItem(
    BuildContext context,
    Pet pet,
    bool isActive,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () =>
          ref.read(activePetIdProvider.notifier).state = pet.supabaseId,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: 200.ms,
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      image: pet.photoUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(pet.photoUrl!),
                              fit: BoxFit.cover,
                              colorFilter: isActive
                                  ? null
                                  : const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.saturation,
                                    ),
                            )
                          : null,
                    ),
                    child: pet.photoUrl == null
                        ? Icon(
                            _getSpeciesIcon(pet.species),
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.grey,
                            size: 30,
                          )
                        : null,
                  ),
                ),
                if (isActive)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.black,
                      ),
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildAddPetButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PetFormScreen())),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle
                      .solid, // Note: standard border doesn't support dash easily
                ),
              ),
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.grey, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Pet pet) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: pet))),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.2,
                child: Icon(Icons.pets, size: 200, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: pet.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: pet.photoUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.pets,
                                color: theme.colorScheme.primary,
                                size: 50,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pet.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pet.breed ?? pet.species,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Healthy State',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUpcomingTimeline(BuildContext context, Pet pet) {
    return Consumer(
      builder: (context, ref, _) {
        final schedulesAsync = ref.watch(
          petSchedulesProvider(pet.supabaseId ?? ''),
        );
        return schedulesAsync.when(
          data: (schedules) {
            final upcoming = schedules.where((s) => !s.isCompleted).toList();
            if (upcoming.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'All caught up for today!',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: upcoming
                  .take(2)
                  .map((s) => _buildTimelineItem(context, s))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const Text('Failed to load reminders'),
        );
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, HealthSchedule schedule) {
    final theme = Theme.of(context);
    final color = _getCategoryColor(schedule.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getCategoryIcon(schedule.type),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Due: ${_formatDate(schedule.startDate)}',
                  style: GoogleFonts.manrope(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Mark as complete logic (already implemented in repository)
            },
            child: const Text('Done'),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildQuickActions(BuildContext context, Pet pet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionItem(
          context,
          Icons.vaccines,
          'Vaccine',
          onTap: () =>
              _navigateToAddSchedule(context, pet.supabaseId, 'vaccine'),
        ),
        _buildActionItem(
          context,
          Icons.medication,
          'Meds',
          onTap: () =>
              _navigateToAddSchedule(context, pet.supabaseId, 'medication'),
        ),
        _buildActionItem(
          context,
          Icons.calendar_today,
          'Vet',
          onTap: () =>
              _navigateToAddSchedule(context, pet.supabaseId, 'appointment'),
        ),
        _buildActionItem(
          context,
          Icons.history,
          'History',
          onTap: () {
            // Future: Navigate to Timeline
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Welcome to Pet Pal',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first pet to start tracking',
              style: GoogleFonts.manrope(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PetFormScreen())),
              child: const Text('Add your first pet'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddSchedule(
    BuildContext context,
    String? petSupabaseId,
    String? type,
  ) {
    if (petSupabaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for sync to complete')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddScheduleScreen(petSupabaseId: petSupabaseId, initialType: type),
      ),
    );
  }

  // Helpers
  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'vaccine':
        return Colors.blue;
      case 'medication':
        return Colors.orange;
      case 'deworming':
        return Colors.purple;
      case 'appointment':
        return Colors.teal;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccine':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'deworming':
        return Icons.bug_report;
      case 'appointment':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today';
    return '${date.day}/${date.month}';
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double dashWidth = 5;
    const double dashSpace = 5;
    final double radius = size.width / 2;
    final double circumference = 2 * 3.1415926535 * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle =
          (i * (dashWidth + dashSpace) / circumference) * 2 * 3.1415926535;
      final double sweepAngle = (dashWidth / circumference) * 2 * 3.1415926535;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
