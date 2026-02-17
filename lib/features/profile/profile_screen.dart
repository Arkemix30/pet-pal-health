import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/local/isar_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/overlays/overlay_manager.dart';
import '../../core/ui/overlays/confirm_dialog.dart';
import '../../core/ui/overlays/success_modal.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: profileAsync.when(
        data: (profile) {
          settingsAsync.whenData((settings) {
            // Settings loaded
          });
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(profileProvider.notifier).syncFromRemote();
              await ref.read(userSettingsProvider.notifier).syncFromRemote();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        _buildHeaderTitle(context),
                        const SizedBox(height: 32),
                        ProfileHeaderWidget(
                          profile: profile,
                          email: user?.email ?? '',
                          onEditTap: () =>
                              _showEditProfileSheet(context, ref, profile),
                          onAvatarTap: () => _showAvatarPicker(context, ref),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Account'),
                        const SizedBox(height: 12),
                        SettingsSection(
                          children: [
                            SettingsTile(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              subtitle: profile?.fullName ?? 'Add your name',
                              onTap: () =>
                                  _showEditProfileSheet(context, ref, profile),
                            ),
                            SettingsTile(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: user?.email ?? 'No email',
                              enabled: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Notifications'),
                        const SizedBox(height: 12),
                        settingsAsync.when(
                          data: (settings) => _buildNotificationSettings(
                            context,
                            ref,
                            settings,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'About'),
                        const SizedBox(height: 12),
                        SettingsSection(
                          children: [
                            SettingsTile(
                              icon: Icons.info_outline,
                              title: 'App Version',
                              subtitle: '1.0.0',
                              enabled: false,
                            ),
                            SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              onTap: () =>
                                  _openUrl('https://petpalhealth.com/privacy'),
                            ),
                            SettingsTile(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              onTap: () =>
                                  _openUrl('https://petpalhealth.com/terms'),
                            ),
                            SettingsTile(
                              icon: Icons.star_outline,
                              title: 'Rate App',
                              onTap: () {},
                            ),
                            SettingsTile(
                              icon: Icons.chat_bubble_outline,
                              title: 'Contact Support',
                              onTap: () =>
                                  _openUrl('mailto:support@petpalhealth.com'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildLogoutButton(context, ref),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Settings',
      style: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSubtle,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNotificationSettings(
    BuildContext context,
    WidgetRef ref,
    UserSettings? settings,
  ) {
    final s = settings ?? UserSettings();
    return SettingsSection(
      children: [
        SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Push Notifications',
          subtitle: 'Enable all notifications',
          trailing: Switch.adaptive(
            value: s.enableNotifications,
            onChanged: (value) {
              ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(enableNotifications: value);
            },
            activeColor: AppTheme.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.vaccines_outlined,
          title: 'Vaccine Reminders',
          subtitle: 'Get notified about upcoming vaccines',
          enabled: s.enableNotifications,
          trailing: Switch.adaptive(
            value: s.enableVaccineReminders,
            onChanged: (value) {
              ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(enableVaccineReminders: value);
            },
            activeColor: AppTheme.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.medication_outlined,
          title: 'Medication Reminders',
          subtitle: 'Get notified about medications',
          enabled: s.enableNotifications,
          trailing: Switch.adaptive(
            value: s.enableMedicationReminders,
            onChanged: (value) {
              ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(enableMedicationReminders: value);
            },
            activeColor: AppTheme.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.calendar_today_outlined,
          title: 'Appointment Reminders',
          subtitle: 'Get notified about vet appointments',
          enabled: s.enableNotifications,
          trailing: Switch.adaptive(
            value: s.enableAppointmentReminders,
            onChanged: (value) {
              ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(enableAppointmentReminders: value);
            },
            activeColor: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context, ref),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          'Log Out',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    Profile? profile,
  ) {
    final nameController = TextEditingController(text: profile?.fullName ?? '');
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(profileProvider.notifier)
                      .updateProfile(fullName: nameController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context); // Close sheet
                    OverlayManager.showPremiumModal(
                      context,
                      child: PremiumSuccessModal(
                        title: 'Profile Updated!',
                        message: 'Successfully updated your info to',
                        petName: nameController.text.trim(),
                        onPrimaryPressed: () => Navigator.pop(context),
                      ),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  await ref
                      .read(profileProvider.notifier)
                      .uploadAvatar(image.path);
                  if (context.mounted) {
                    OverlayManager.showToast(
                      context,
                      message: 'Profile picture updated!',
                      type: ToastType.success,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  await ref
                      .read(profileProvider.notifier)
                      .uploadAvatar(image.path);
                  if (context.mounted) {
                    OverlayManager.showToast(
                      context,
                      message: 'Profile picture updated!',
                      type: ToastType.success,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await OverlayManager.showPremiumModal<bool>(
      context,
      child: PremiumConfirmDialog(
        title: 'Log Out',
        message: 'Are you sure you want to log out of Pet Pal Health?',
        confirmLabel: 'Log Out',
        isDestructive: true,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      await ref.read(logoutProvider)();
    }
  }

  void _openUrl(String url) {
    // Implement URL launcher here
  }
}
