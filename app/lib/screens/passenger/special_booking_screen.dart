import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/location_search_field.dart';

class SpecialBookingScreen extends StatefulWidget {
  const SpecialBookingScreen({super.key});

  @override
  State<SpecialBookingScreen> createState() => _SpecialBookingScreenState();
}

class _SpecialBookingScreenState extends State<SpecialBookingScreen> {
  static const LatLng _initialPosition = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  bool _isSearching = false;

  final TextEditingController _passengersController = TextEditingController(
    text: '1',
  );
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _fareController = TextEditingController(
    text: '200',
  );


  String get _formattedDateTime {
    if (_selectedDate == null) return 'Date and time';
    final datePart = DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
    if (_selectedTime == null) return datePart;
    final timePart = _selectedTime!.format(context);
    return '$datePart  \u2022  $timePart';
  }

  Future<void> _pickDateAndTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: AppColors.black,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: AppColors.white,
                    surface: AppColors.white,
                    onSurface: AppColors.black,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: AppColors.black,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: AppColors.white,
                    surface: AppColors.white,
                    onSurface: AppColors.black,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  @override
  void dispose() {
    _passengersController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _commentController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _showFareDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tempController = TextEditingController(text: _fareController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          title: Text(
            'Set fare amount',
            style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
          ),
          content: TextField(
            controller: tempController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tempController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      _fareController.text = result;
      setState(() {});
    }
  }

  Future<void> _showCommentDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          title: Text(
            'Add a note',
            style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
          ),
          content: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special instructions for the driver?',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            options: const MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.5,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? "https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                    : "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                },
                userAgentPackageName: 'com.kenickvip.app',
                maxZoom: 22,
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),

          // Bottom Sheet / Card
          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.08,
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.08, 0.75],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Number of passengers
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF5F0EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: isDark ? AppColors.white : Colors.black87,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Passengers',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 10,
                                ),
                                controller: _passengersController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date and time
                      GestureDetector(
                        onTap: _pickDateAndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF5F0EF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: _selectedDate != null
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.white
                                                : Colors.black87),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _formattedDateTime,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _selectedDate != null
                                              ? AppColors.primary
                                              : (isDark
                                                    ? AppColors.white
                                                    : AppColors.black),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Event type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF5F0EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_note,
                                  color: isDark
                                      ? AppColors.white
                                      : Colors.black87,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Event type',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Comments
                      GestureDetector(
                        onTap: _showCommentDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF5F0EF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment,
                                    color: _commentController.text.isNotEmpty
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.white
                                              : Colors.black87),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    _commentController.text.isNotEmpty
                                        ? 'Note added'
                                        : 'Comments',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          _commentController.text.isNotEmpty
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _commentController.text.isNotEmpty
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.white
                                                : AppColors.black),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Inputs with timeline
                      Stack(
                        children: [
                          Positioned(
                            left: 11,
                            top: 25,
                            bottom: 25,
                            child: Container(
                              width: 2,
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: LocationSearchField(
                                      hint: 'Current Location',
                                      controller: _fromController,
                                      isDark: isDark,
                                      onSelected: (_) {},
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: LocationSearchField(
                                      hint: 'Where to?',
                                      controller: _toController,
                                      isDark: isDark,
                                      onSelected: (_) {},
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fare Display
                      GestureDetector(
                        onTap: _showFareDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF5F0EF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${_fareController.text}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.white
                                            : AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to set fare',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Request Estimate Button
                      CustomButton(
                        title: _isSearching ? 'Requesting estimate...' : 'Request estimate',
                        isLoading: _isSearching,
                        onPress: () async {
                          if (_isSearching) return;
                          setState(() => _isSearching = true);
                          // Simulate requesting an estimate
                          await Future.delayed(const Duration(seconds: 4));
                          if (context.mounted) {
                            setState(() => _isSearching = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Estimate requested successfully!')),
                            );
                          }
                        },
                        variant: ButtonVariant.primary,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
              );
            },
          ),
        ],
      ),
    );
  }
}
