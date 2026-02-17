import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import '../../core/ui/overlays/overlay_manager.dart';
import '../../core/ui/overlays/confirm_dialog.dart';
import 'vet_provider.dart';
import 'vet_form_screen.dart';

class VetScreen extends ConsumerStatefulWidget {
  const VetScreen({super.key});

  @override
  ConsumerState<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends ConsumerState<VetScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final vetsAsync = ref.watch(vetsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Vet Directory',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: vetsAsync.when(
        data: (vets) {
          final filteredVets = vets.where((v) {
            final matchesSearch = v.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesFilter =
                _selectedFilter == 'All' ||
                (_selectedFilter == 'Emergency' &&
                    v.notes?.contains('Emergency') == true) ||
                (_selectedFilter == 'Specialty' && v.specialty != null);
            return matchesSearch && matchesFilter;
          }).toList();

          final favoriteVets = vets.where((v) => v.isFavorite).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(vetManagementProvider).syncVetsFromRemote();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Favorites Section
                if (favoriteVets.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Text(
                        'Favorites',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: favoriteVets.length,
                        itemBuilder: (context, index) {
                          return _FavoriteVetCard(vet: favoriteVets[index]);
                        },
                      ),
                    ),
                  ),
                ],

                // Search & Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _VetSearchBar(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _VetFilterChips(
                      selectedFilter: _selectedFilter,
                      onFilterSelected: (filter) =>
                          setState(() => _selectedFilter = filter),
                    ),
                  ),
                ),

                // Main List
                if (filteredVets.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final vet = filteredVets[index];
                        return _PremiumVetCard(
                              vet: vet,
                              onTap: () => _editVet(context, vet),
                              onDelete: () => _deleteVet(context, ref, vet),
                              onToggleFavorite: () => _toggleFavorite(vet),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50))
                            .slideY(begin: 0.1, end: 0);
                      }, childCount: filteredVets.length),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: const Color(0xFF112116),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Vet',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No vets found',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search'
                : 'Add your first veterinarian',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addVet(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const VetFormScreen()));
  }

  void _editVet(BuildContext context, Vet vet) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => VetFormScreen(vet: vet)));
  }

  void _toggleFavorite(Vet vet) {
    vet.isFavorite = !vet.isFavorite;
    ref.read(vetManagementProvider).saveVet(vet);
  }

  void _deleteVet(BuildContext context, WidgetRef ref, Vet vet) async {
    final confirmed = await OverlayManager.showPremiumModal<bool>(
      context,
      child: PremiumConfirmDialog(
        title: 'Delete Vet',
        message: 'Are you sure you want to delete ${vet.name}?',
        confirmLabel: 'Delete',
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true) {
      await ref.read(vetManagementProvider).deleteVet(vet.id, vet.supabaseId);
      if (context.mounted) {
        OverlayManager.showToast(
          context,
          message: 'Vet profile removed',
          type: ToastType.success,
        );
      }
    }
  }
}

class _VetSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _VetSearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search for vets, clinics...',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _VetFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const _VetFilterChips({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Open Now', 'Emergency', 'Specialty'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filter),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: GoogleFonts.manrope(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200]!,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FavoriteVetCard extends StatelessWidget {
  final Vet vet;

  const _FavoriteVetCard({required this.vet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12, left: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vet.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.red[400],
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumVetCard extends StatelessWidget {
  final Vet vet;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _PremiumVetCard({
    required this.vet,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinic Icon/Image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vet.name,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${vet.rating ?? 4.8}',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  ' (${vet.ratingCount ?? 42})',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${vet.distance ?? 1.2} miles away',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Favorite Toggle
                      IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          vet.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: vet.isFavorite
                              ? Colors.red[400]
                              : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Divider
            Divider(height: 1, color: Colors.grey[100]),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    onTap: () {
                      OverlayManager.showToast(
                        context,
                        message: 'Calling ${vet.name}...',
                      );
                    },
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey[200]),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.directions_rounded,
                    label: 'Directions',
                    onTap: () {
                      OverlayManager.showToast(
                        context,
                        message: 'Opening maps...',
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[300],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
