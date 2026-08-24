import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:kenick_vip/widgets/inputs/location_search_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; _error = 'Not authenticated'; });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('saved_places')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _places = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'Failed to load saved places'; });
      }
    }
  }

  Future<void> _deletePlace(String id) async {
    try {
      await Supabase.instance.client.from('saved_places').delete().eq('id', id);
      if (mounted) {
        setState(() => _places.removeWhere((p) => p['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove place')),
        );
      }
    }
  }

  void _showAddPlaceDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    LocationSearchResult? selectedLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Saved Place',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Place name (e.g. Home, Office)',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    LocationSearchField(
                      hint: 'Search address',
                      controller: addressController,
                      isDark: isDark,
                      onSelected: (r) {
                        setSheetState(() => selectedLocation = r);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (addressController.text.trim().isEmpty) return;
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) return;
                          try {
                            final insertData = <String, dynamic>{
                              'user_id': user.id,
                              'name': nameController.text.trim(),
                              'address': addressController.text.trim(),
                            };
                            if (selectedLocation != null) {
                              insertData['latitude'] = selectedLocation!.latitude;
                              insertData['longitude'] = selectedLocation!.longitude;
                            }
                            final response = await Supabase.instance.client
                                .from('saved_places')
                                .insert(insertData)
                                .select()
                                .single();
                            if (mounted) {
                              setState(() => _places.insert(0, response));
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Place saved')),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save place')),
                              );
                            }
                          }
                        },
                        child: const Text('Save Place'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('work') || lower.contains('office')) return Icons.work_rounded;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('school') || lower.contains('university')) return Icons.school_rounded;
    if (lower.contains('airport')) return Icons.flight_rounded;
    return Icons.location_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Saved Places'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlaceDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Place'),
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(3, (i) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 80, avatarSize: 44),
          )),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 36, color: cs.error),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text('Something went wrong',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _fetchPlaces,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_location_alt_rounded,
                    size: 40, color: cs.onPrimaryContainer),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text('No saved places',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Save your favourite locations\nfor faster booking.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showAddPlaceDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Place'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPlaces,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _places.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final place = _places[index];
          final name = place['name'] as String? ?? 'Unknown';
          final address = place['address'] as String? ?? '';

          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: Dismissible(
              key: ValueKey(place['id']),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _deletePlace(place['id']),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_rounded, color: cs.onError, size: 24),
              ),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForName(name), size: 20, color: cs.onPrimaryContainer),
                  ),
                  title: Text(name),
                  subtitle: address.isNotEmpty ? Text(address, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
