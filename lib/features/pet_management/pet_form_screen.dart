import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import '../../core/services/storage_service.dart';
import 'pet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  final Pet? initialPet;
  const PetFormScreen({super.key, this.initialPet});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late String _selectedSpecies;
  late String _weightUnit; // 'kg' or 'lbs'
  DateTime? _birthDate;
  File? _selectedImageFile;
  String? _currentPhotoUrl;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _speciesOptions = [
    {'name': 'Dog', 'icon': Icons.pets},
    {'name': 'Cat', 'icon': Icons.cruelty_free},
    {'name': 'Bird', 'icon': Icons.flutter_dash},
    {'name': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialPet;
    _nameController = TextEditingController(text: p?.name);
    _breedController = TextEditingController(text: p?.breed);
    _weightController = TextEditingController(
      text: p?.weightKg != null ? p!.weightKg.toString() : '',
    );
    _selectedSpecies = p?.species ?? 'Dog';
    _birthDate = p?.birthDate;
    _currentPhotoUrl = p?.photoUrl;
    _weightUnit = 'kg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _selectedImageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String? finalPhotoUrl = _currentPhotoUrl;

      if (_selectedImageFile != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          finalPhotoUrl = await ref
              .read(storageServiceProvider)
              .uploadPetPhoto(_selectedImageFile!, userId);
        }
      }

      double? weightVal = double.tryParse(_weightController.text);
      if (weightVal != null && _weightUnit == 'lbs') {
        weightVal = weightVal * 0.453592; // Convert lbs to kg
      }

      final pet = (widget.initialPet ?? Pet())
        ..name = _nameController.text.trim()
        ..species = _selectedSpecies
        ..breed = _breedController.text.trim()
        ..birthDate = _birthDate
        ..weightKg = weightVal
        ..photoUrl = finalPhotoUrl
        ..createdAt = widget.initialPet?.createdAt ?? DateTime.now();

      await ref.read(petManagementProvider).savePet(pet);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving pet: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialPet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pet Profile' : 'Add Pet Profile'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildImagePicker(theme),
                  const SizedBox(height: 48),
                  _buildLabel('PET NAME'),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.firaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(hintText: 'e.g. Bella'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Name required' : null,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),
                  _buildLabel('SPECIES'),
                  _buildSpeciesSelector(theme).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  _buildLabel('BREED'),
                  TextFormField(
                    controller: _breedController,
                    style: GoogleFonts.firaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Golden Retriever',
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.search, size: 24, color: Colors.grey),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),
                  _buildLabel('DATE OF BIRTH'),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _birthDate == null
                                ? 'Select Date'
                                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                            style: GoogleFonts.firaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _birthDate == null
                                  ? Colors.grey
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),
                  _buildLabel('WEIGHT'),
                  _buildWeightInput(theme).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withValues(alpha: 0),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _save,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isEditing ? 'Update Profile' : 'Create Profile'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            "Let's meet your best friend",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Enter your pet's details to start tracking\ntheir health journey.",
            textAlign: TextAlign.center,
            style: GoogleFonts.firaSans(
              fontSize: 15,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildWeightInput(ThemeData theme) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.firaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: '0.0',
            contentPadding: EdgeInsets.only(
              left: 24,
              top: 18,
              bottom: 18,
              right: 110,
            ),
          ),
        ),
        Positioned(
          right: 10,
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildUnitToggle('kg'), _buildUnitToggle('lbs')],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String unit) {
    final isSelected = _weightUnit == unit;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _weightUnit = unit),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            unit,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesSelector(ThemeData theme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _speciesOptions.length,
        itemBuilder: (context, index) {
          final option = _speciesOptions[index];
          final isSelected = _selectedSpecies == option['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecies = option['name']),
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    option['icon'],
                    color: isSelected
                        ? Colors.black
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option['name'],
                    style: GoogleFonts.outfit(
                      color: isSelected
                          ? Colors.black
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
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

  Widget _buildImagePicker(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: DottedCirclePainter(
                    color: theme.colorScheme.primary,
                  ),
                  child: Container(
                    width: 156,
                    height: 156,
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        image: _selectedImageFile != null
                            ? DecorationImage(
                                image: FileImage(_selectedImageFile!),
                                fit: BoxFit.cover,
                              )
                            : (_currentPhotoUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        _currentPhotoUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child:
                          (_selectedImageFile == null &&
                              _currentPhotoUrl == null)
                          ? Icon(
                              Icons.pets,
                              size: 50,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ).animate().scale(curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 16),
          Text(
            'UPLOAD PHOTO',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final double circumference = 2 * pi * radius;
    const double dashLength = 8;
    const double dashSpace = 6;
    final int dashCount = (circumference / (dashLength + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashLength + dashSpace)) / radius;
      final double endAngle = startAngle + (dashLength / radius);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
