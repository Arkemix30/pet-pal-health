import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/local/isar_models.dart';
import '../health_schedules/schedule_provider.dart';
import '../pet_management/pet_provider.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final petsAsync = ref.watch(petsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Health Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateReport(ref),
            tooltip: 'Export Health Report',
          ),
        ],
      ),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return _buildEmptyState();
          }

          final upcoming = schedules.where((s) => !s.isCompleted).toList();
          final history = schedules
              .where((s) => s.isCompleted)
              .toList()
              .reversed
              .toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (upcoming.isNotEmpty) ...[
                _buildHeader('Upcoming Essentials'),
                const SizedBox(height: 16),
                ...upcoming.map(
                  (s) => _TimelineTile(schedule: s, isUpcoming: true),
                ),
                const SizedBox(height: 32),
              ],
              if (history.isNotEmpty) ...[
                _buildHeader('Health History'),
                const SizedBox(height: 16),
                ...history.map(
                  (s) => _TimelineTile(schedule: s, isUpcoming: false),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D6A4F),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nothing scheduled yet',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(WidgetRef ref) async {
    final schedules = ref.read(allSchedulesProvider).value ?? [];
    final pets = ref.read(petsStreamProvider).value ?? [];

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Pet Health Export - ${DateTime.now().toString().split(' ')[0]}',
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Pets Summary:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          ...pets.map(
            (p) => pw.Bullet(
              text: '${p.name} (${p.species}) - ${p.breed ?? "N/A"}',
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            'Health Records:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['Pet', 'Action', 'Type', 'Date', 'Status'],
            data: schedules.map((s) {
              final pet = pets.firstWhere(
                (p) => p.supabaseId == s.petSupabaseId,
                orElse: () => Pet()..name = 'Unknown',
              );
              return [
                pet.name,
                s.title,
                s.type,
                s.startDate.toString().split(' ')[0],
                s.isCompleted ? 'Done' : 'Pending',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}

class _TimelineTile extends StatelessWidget {
  final HealthSchedule schedule;
  final bool isUpcoming;
  const _TimelineTile({required this.schedule, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isUpcoming ? const Color(0xFF2D6A4F) : Colors.grey)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpcoming ? _getIcon(schedule.type) : Icons.check_circle,
              color: isUpcoming ? const Color(0xFF2D6A4F) : Colors.grey,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isUpcoming
                      ? 'Due: ${schedule.startDate.toString().split(' ')[0]}'
                      : 'Completed: ${schedule.completedAt?.toString().split(' ')[0] ?? "N/A"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
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
}
