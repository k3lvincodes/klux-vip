import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController();
  String _selectedColor = '';
  bool _isLoading = false;
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final List<File> _pickedImages = [];
  bool _isUploadingImages = false;

  final List<String> _colors = [
    'Black',
    'White',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Brown',
    'Beige',
    'Gold',
  ];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _pickedImages.length;
    if (remaining <= 0) {
      CustomToast.showError(context, 'Maximum 5 images allowed');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 95);
    if (picked.isEmpty) return;

    final toAdd = picked.take(remaining).map((f) => File(f.path)).toList();
    setState(() => _pickedImages.addAll(toAdd));

    if (toAdd.length < picked.length && mounted) {
      CustomToast.showInfo(context, 'Only $remaining images added (max 5)');
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    setState(() => _isUploadingImages = true);
    for (final image in _pickedImages) {
      final url = await CloudinaryService.uploadImage(image);
      if (url != null) urls.add(url);
    }
    setState(() => _isUploadingImages = false);
    return urls;
  }

  Future<void> _handleSubmit() async {
    if (_makeController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _licensePlateController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty ||
        _selectedColor.isEmpty) {
      CustomToast.showError(context, 'Please fill all fields');
      return;
    }

    if (_pickedImages.isEmpty) {
      CustomToast.showError(context, 'Please upload at least one car image');
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    if (year == null || year < 2000 || year > DateTime.now().year + 1) {
      CustomToast.showError(context, 'Please enter a valid year');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await _uploadImages();

      if (imageUrls.isEmpty) {
        if (mounted) {
          CustomToast.showError(context, 'Failed to upload images');
        }
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _vehicleRepo.registerVehicle(
          driverId: user.id,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: year,
          color: _selectedColor,
          licensePlate: _licensePlateController.text.trim(),
          images: imageUrls,
        );
      }

      if (mounted) {
        CustomToast.showSuccess(context, 'Vehicle registered successfully!');
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to register vehicle');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Register Your Vehicle',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _buildImagePicker(context),
              const SizedBox(height: 24),
              _buildInput(
                controller: _makeController,
                hintText: 'Make (e.g., Toyota, Honda, Ford)',
                icon: Icons.directions_car_outlined,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _modelController,
                hintText: 'Model (e.g., Camry, Civic, F-150)',
                icon: Icons.directions_car_outlined,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _yearController,
                hintText: 'Year',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildColorSelector(context),
              const SizedBox(height: 20),
              _buildInput(
                controller: _licensePlateController,
                hintText: 'License Plate',
                icon: Icons.tag,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 40),
              CustomButton(
                title: _isLoading || _isUploadingImages
                    ? 'Uploading...'
                    : 'Register Vehicle',
                onPress:
                    _isLoading || _isUploadingImages ? () {} : _handleSubmit,
                variant: ButtonVariant.primary,
                height: 48,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/driver-home'),
                  child: Text(
                    'Skip',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Images',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _pickedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorScheme.inverseSurface.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: colorScheme.onInverseSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_pickedImages.isNotEmpty)
                const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickedImages.length >= 5 ? null : _pickImages,
                child: Container(
                  width: double.infinity,
                  height: _pickedImages.isEmpty ? 140 : 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: _pickedImages.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload car images',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_pickedImages.length}/5',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 22,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add more (${_pickedImages.length}/5)',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              scrollPadding: const EdgeInsets.only(bottom: 10),
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedColor.isEmpty ? 'Color' : _selectedColor,
              style: textTheme.bodyMedium?.copyWith(
                color: _selectedColor.isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getColorFromName(_selectedColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Color',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = color);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 60,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getColorFromName(color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedColor == color
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: _selectedColor == color ? 2 : 1,
                            ),
                          ),
                          child: _selectedColor == color
                              ? Icon(
                                  Icons.check,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'silver':
        return Colors.grey.shade300;
      case 'gray':
        return Colors.grey;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'gold':
        return const Color(0xFFFFD700);
      default:
        return Colors.grey;
    }
  }
}
