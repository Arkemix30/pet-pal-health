import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import 'schedule_provider.dart';
import 'add_schedule_screen.dart';

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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPetInfo(theme),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Health Tasks',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF2D6A4F),
                        ),
                        onPressed: () {
                          if (pet.supabaseId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please wait for sync to complete',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddScheduleScreen(
                                petSupabaseId: pet.supabaseId!,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  schedulesAsync.when(
                    data: (schedules) {
                      if (schedules.isEmpty) {
                        return const Center(
                          child: Text('No upcoming tasks scheduled'),
                        );
                      }
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
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading schedules: $e'),
                  ),
                  const SizedBox(height: 100), // Padding for bottom
                ],
              ),
            ),
          ),
        ],
      ),
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

class _ScheduleTile extends StatelessWidget {
  final HealthSchedule schedule;
  const _ScheduleTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(schedule.type),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          schedule.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatDate(schedule.startDate)),
        trailing: const Icon(Icons.chevron_right, size: 16),
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
