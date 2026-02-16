import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import 'schedule_provider.dart';
import 'add_schedule_screen.dart';
import '../sharing/sharing_screen.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                pet.name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              background: pet.photoUrl != null
                  ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  if (pet.supabaseId == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SharingScreen(pet: pet)),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPetInfo(theme),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    'Upcoming Tasks',
                    onAdd: () => _navigateToAddSchedule(context),
                  ),
                  const SizedBox(height: 16),
                  schedulesAsync.when(
                    data: (schedules) {
                      final upcoming = schedules
                          .where((s) => !s.isCompleted)
                          .toList();
                      if (upcoming.isEmpty) {
                        return const Center(
                          child: Text('No upcoming tasks scheduled'),
                        );
                      }
                      return _buildScheduleList(upcoming);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading schedules: $e'),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Recent History'),
                  const SizedBox(height: 16),
                  schedulesAsync.when(
                    data: (schedules) {
                      final history = schedules
                          .where((s) => s.isCompleted)
                          .toList();
                      if (history.isEmpty) {
                        return const Center(
                          child: Text('No completed tasks yet'),
                        );
                      }
                      return _buildScheduleList(history);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSchedule(BuildContext context) {
    if (pet.supabaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for sync to complete')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(petSupabaseId: pet.supabaseId!),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF2D6A4F)),
            onPressed: onAdd,
          ),
      ],
    );
  }

  Widget _buildScheduleList(List<HealthSchedule> schedules) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return _ScheduleTile(
          schedule: schedules[index],
        ).animate().fadeIn(delay: (index * 100).ms).slideX();
      },
    );
  }

  Widget _buildPetInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.category, pet.species, 'Species'),
          _infoItem(Icons.info_outline, pet.breed ?? 'N/A', 'Breed'),
          _infoItem(Icons.cake, _formatAge(pet.birthDate), 'Age'),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  String _formatAge(DateTime? birthDate) {
    if (birthDate == null) return 'N/A';
    final age = DateTime.now().year - birthDate.year;
    return '$age yrs';
  }
}

class _ScheduleTile extends ConsumerWidget {
  final HealthSchedule schedule;
  const _ScheduleTile({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: schedule.isCompleted
              ? Colors.green.withOpacity(0.2)
              : Colors.grey[100]!,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (schedule.isCompleted
                        ? Colors.green
                        : theme.colorScheme.primary)
                    .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            schedule.isCompleted ? Icons.check : _getIcon(schedule.type),
            color: schedule.isCompleted
                ? Colors.green
                : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          schedule.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: schedule.isCompleted
                ? TextDecoration.lineThrough
                : null,
            color: schedule.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          schedule.isCompleted
              ? 'Completed on ${_formatDate(schedule.completedAt ?? schedule.startDate)}'
              : _formatDate(schedule.startDate),
        ),
        trailing: !schedule.isCompleted
            ? IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey,
                ),
                onPressed: () => _markAsDone(context, ref),
              )
            : null,
      ),
    );
  }

  void _markAsDone(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Task?'),
        content: Text('Did you complete "${schedule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(scheduleManagementProvider).completeSchedule(schedule);
              Navigator.pop(ctx);
            },
            child: const Text('Yes, Done'),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'vaccine':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.local_hospital;
      default:
        return Icons.pets;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
