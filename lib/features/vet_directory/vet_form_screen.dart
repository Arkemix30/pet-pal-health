import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/local/isar_models.dart';
import '../../core/ui/overlays/overlay_manager.dart';
import '../../core/ui/overlays/success_modal.dart';
import 'vet_provider.dart';

class VetFormScreen extends ConsumerStatefulWidget {
  final Vet? vet;

  const VetFormScreen({super.key, this.vet});

  @override
  ConsumerState<VetFormScreen> createState() => _VetFormScreenState();
}

class _VetFormScreenState extends ConsumerState<VetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _ratingController;
  late bool _isFavorite;
  bool _isLoading = false;

  bool get isEditing => widget.vet != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vet?.name ?? '');
    _phoneController = TextEditingController(text: widget.vet?.phone ?? '');
    _addressController = TextEditingController(text: widget.vet?.address ?? '');
    _notesController = TextEditingController(text: widget.vet?.notes ?? '');
    _specialtyController = TextEditingController(
      text: widget.vet?.specialty ?? '',
    );
    _ratingController = TextEditingController(
      text: widget.vet?.rating?.toString() ?? '',
    );
    _isFavorite = widget.vet?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _specialtyController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Vet' : 'Add Vet',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Vet Name / Clinic Name',
              hint: 'Enter vet or clinic name',
              icon: Icons.local_hospital,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _specialtyController,
              label: 'Specialty',
              hint: 'e.g. Surgeon, General, Emergency',
              icon: Icons.star_border,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ratingController,
                    label: 'Rating (0-5)',
                    hint: '4.5',
                    icon: Icons.star_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorite',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _isFavorite,
                        onChanged: (val) => setState(() => _isFavorite = val),
                        title: const Text('Add to favorites'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter phone number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'Enter address',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Any additional notes',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: const Color(0xFF112116),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF112116)),
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Vet' : 'Add Vet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Future<void> _saveVet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vet = widget.vet ?? Vet();
      vet.name = _nameController.text.trim();
      vet.phone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;
      vet.address = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null;
      vet.notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;
      vet.specialty = _specialtyController.text.trim().isNotEmpty
          ? _specialtyController.text.trim()
          : null;
      vet.rating = double.tryParse(_ratingController.text.trim());
      vet.isFavorite = _isFavorite;

      await ref.read(vetManagementProvider).saveVet(vet);

      if (mounted) {
        OverlayManager.showPremiumModal(
          context,
          child: PremiumSuccessModal(
            title: isEditing ? 'Vet Updated!' : 'Vet Added!',
            message: isEditing
                ? 'Information saved for'
                : 'Successfully registered',
            petName: _nameController.text.trim(),
            onPrimaryPressed: () {
              Navigator.of(context).pop(); // Close modal
              Navigator.of(context).pop(); // Go back
            },
          ),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
