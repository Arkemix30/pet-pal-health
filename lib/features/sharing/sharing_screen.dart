import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import '../../core/ui/overlays/overlay_manager.dart';
import '../../core/ui/overlays/confirm_dialog.dart';
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
      OverlayManager.showToast(
        context,
        message: 'Please enter a valid email',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .inviteUser(petSupabaseId: widget.pet.supabaseId!, email: email);
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: 'Invitation sent to $email',
          type: ToastType.success,
        );
        _emailController.clear();
      }
    } catch (e) {
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                color: theme.colorScheme.primary.withOpacity(0.05),
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
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                        ),
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
            StreamBuilder<List<PetShare>>(
              stream: ref
                  .watch(sharingRepositoryProvider)
                  .watchSharedUsers(widget.pet.supabaseId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sharedUsers = snapshot.data ?? [];

                if (sharedUsers.isEmpty) {
                  return _buildShareTile(
                    'Currently, only you have access.',
                    isPlaceholder: true,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sharedUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = sharedUsers[index];
                    return _buildSharedUserTile(user);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedUserTile(PetShare share) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              (share.sharedWithEmail?.isNotEmpty == true)
                  ? share.sharedWithEmail![0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.sharedWithEmail ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  share.accessLevel == 'editor' ? 'Can edit' : 'View only',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _confirmRevoke(share),
            tooltip: 'Revoke access',
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(PetShare share) async {
    final confirmed = await OverlayManager.showPremiumModal<bool>(
      context,
      child: PremiumConfirmDialog(
        title: 'Revoke Access',
        message:
            'Are you sure you want to remove ${share.sharedWithEmail} from accessing ${widget.pet.name}?',
        confirmLabel: 'Revoke',
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true) {
      _revokeAccess(share);
    }
  }

  Future<void> _revokeAccess(PetShare share) async {
    try {
      await ref.read(sharingRepositoryProvider).revokeAccess(share.supabaseId!);
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: 'Access revoked',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Widget _buildShareTile(String title, {bool isPlaceholder = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isPlaceholder
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.onSurface,
                fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
