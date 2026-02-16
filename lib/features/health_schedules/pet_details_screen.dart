import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import 'schedule_provider.dart';
import 'add_schedule_screen.dart';
import '../sharing/sharing_screen.dart';
import '../pet_management/pet_form_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pet_management/pet_history_screen.dart';

class PetDetailsScreen extends ConsumerWidget {
  final Pet pet;
  const PetDetailsScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(
      petSchedulesProvider(pet.supabaseId ?? ''),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pet Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PetFormScreen(initialPet: pet)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              if (pet.supabaseId == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SharingScreen(pet: pet)),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(context),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        'Up Next',
                        trailing: Text(
                          'See Calendar',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      schedulesAsync.when(
                        data: (schedules) {
                          final upcoming = schedules
                              .where((s) => !s.isCompleted)
                              .toList();
                          return _buildTimeline(context, upcoming, ref);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'Quick Actions'),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddSchedule(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ).animate().scale(curve: Curves.easeOutBack),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    width: 4,
                  ),
                  image: pet.photoUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(pet.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pet.photoUrl == null
                    ? Icon(
                        Icons.pets,
                        size: 60,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      )
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF19E65E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          pet.name,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatAge(pet.birthDate)} • ${pet.breed ?? pet.species}',
          style: GoogleFonts.firaSans(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF19E65E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF19E65E).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFF19E65E)),
              const SizedBox(width: 8),
              Text(
                'ALL SYSTEMS GOOD',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF19E65E),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'WEIGHT',
            '${pet.weightKg ?? 0}',
            'kg',
            status: 'Stable',
            icon: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'ACTIVITY',
            'High',
            '',
            status: '+5%',
            isImprovement: true,
            icon: Icons.favorite_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit, {
    required String status,
    bool isImprovement = true,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isImprovement ? const Color(0xFF19E65E) : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isImprovement
                        ? const Color(0xFF19E65E)
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<HealthSchedule> schedules,
    WidgetRef ref,
  ) {
    if (schedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'No upcoming tasks',
            style: GoogleFonts.outfit(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: schedules.take(2).map((s) {
        final index = schedules.indexOf(s);
        final isFirst = index == 0;
        return _buildTimelineItem(context, s, isFirst, ref);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    HealthSchedule s,
    bool isFirst,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final indicatorColor = isFirst
        ? const Color(0xFF19E65E)
        : Colors.grey.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                    boxShadow: isFirst
                        ? [
                            BoxShadow(
                              color: indicatorColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _getIcon(s.type),
                    size: 16,
                    color: isFirst ? Colors.black : Colors.white,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withValues(alpha: 0.1),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isFirst
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: isFirst
                      ? Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isFirst
                                      ? theme.colorScheme.onSurface
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${_formatDueDate(s.startDate)}',
                                style: GoogleFonts.firaSans(
                                  color: isFirst
                                      ? Colors.red.withValues(alpha: 0.7)
                                      : Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    if (isFirst) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _markAsDone(context, ref, s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF19E65E),
                          elevation: 0,
                          side: BorderSide(
                            color: const Color(
                              0xFF19E65E,
                            ).withValues(alpha: 0.3),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Mark as Given',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildActionItem(
          context,
          Icons.vaccines_outlined,
          'Log\nVaccine',
          onTap: () => _navigateToAddSchedule(context, type: 'vaccine'),
        ),
        _buildActionItem(
          context,
          Icons.medical_services_outlined,
          'Add\nMeds',
          onTap: () => _navigateToAddSchedule(context, type: 'medication'),
        ),
        _buildActionItem(
          context,
          Icons.calendar_month_outlined,
          'Book\nVet',
          onTap: () => _navigateToAddSchedule(context, type: 'appointment'),
        ),
        _buildActionItem(
          context,
          Icons.history,
          'View\nHistory',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => PetHistoryScreen(pet: pet))),
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF19E65E), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _markAsDone(BuildContext context, WidgetRef ref, HealthSchedule s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Complete Task?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text('Did you complete "${s.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 45)),
            onPressed: () {
              ref.read(scheduleManagementProvider).completeSchedule(s);
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSchedule(BuildContext context, {String? type}) {
    if (pet.supabaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for sync to complete')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(
          petSupabaseId: pet.supabaseId!,
          initialType: type,
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccine':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.local_hospital;
      case 'flea & tick':
        return Icons.bug_report;
      default:
        return Icons.pets;
    }
  }

  String _formatAge(DateTime? birthDate) {
    if (birthDate == null) return 'N/A';
    final age = DateTime.now().year - birthDate.year;
    return '$age Years Old';
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today, 8:00 AM';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day} • Vet Clinic';
  }
}
