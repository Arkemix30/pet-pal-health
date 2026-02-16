import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import 'sharing_repository.dart';

class SharingScreen extends ConsumerStatefulWidget {
  final Pet pet;
  const SharingScreen({super.key, required this.pet});

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends ConsumerState<SharingScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _inviteUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .inviteUser(petSupabaseId: widget.pet.supabaseId!, email: email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
        _emailController.clear();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Share ${widget.pet.name}', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Color(0xFF2D6A4F),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Family Sharing',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite family members or sitters to help manage ${widget.pet.name}\'s health.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 32),
            Text(
              'Invite via Email',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'email@example.com',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _inviteUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Invite'),
                      ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Manage Access',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder for shared users list
            _buildShareTile(
              'Currently, only you have access.',
              isPlaceholder: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTile(String title, {bool isPlaceholder = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isPlaceholder ? Colors.grey : Colors.black,
                fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
