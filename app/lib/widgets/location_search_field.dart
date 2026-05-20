import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final ValueChanged<LocationSearchResult>? onSelected;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDark,
    this.onSelected,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  List<LocationSearchResult> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _dropdownVisible = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.text.isEmpty && _dropdownVisible) {
      _hideDropdown();
    }
  }

  void _showDropdown() {
    if (_dropdownVisible) return;
    setState(() => _dropdownVisible = true);
  }

  void _hideDropdown() {
    if (!_dropdownVisible) return;
    setState(() => _dropdownVisible = false);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = []);
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      final results = await LocationSearchService.search(query);
      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isSearching = false;
      });

      if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  Future<void> _onSelectCurrentLocation() async {
    _hideDropdown();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) return;
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in app settings.')),
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.white,
          title: Text('Enable Location', style: TextStyle(color: widget.isDark ? AppColors.white : AppColors.black)),
          content: Text('Location services are disabled. Please enable them to use your current location.', style: TextStyle(color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Settings', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      await Geolocator.openLocationSettings();
      // Wait briefly for the user to return
      await Future.delayed(const Duration(seconds: 1));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    if (!mounted) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final result = await LocationSearchService.reverseGeocode(
        LatLng(pos.latitude, pos.longitude),
      );

      if (!mounted) return;

      final placeName = result?.placeName ?? 'Current Location';
      widget.controller.text = placeName;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: placeName.length),
      );

      if (result != null) {
        widget.onSelected?.call(result);
      } else {
        widget.onSelected?.call(
          LocationSearchResult(
            placeName: placeName,
            latitude: pos.latitude,
            longitude: pos.longitude,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
    }
  }

  void _onSelectResult(LocationSearchResult result) {
    _hideDropdown();
    widget.controller.text = result.placeName;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: result.placeName.length),
    );
    widget.onSelected?.call(result);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkBackground
                : const Color(0xFFF5F0EF),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: TextField(
            scrollPadding: const EdgeInsets.only(bottom: 10),
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: widget.isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixIcon: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : null,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? AppColors.white : AppColors.black,
            ),
            onChanged: _onSearchChanged,
            onTap: _showDropdown,
          ),
        ),
        if (_dropdownVisible)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildDropdown(),
          ),
      ],
    );
  }

  Widget _buildDropdown() {
    final items = <Widget>[];

    items.add(_buildCurrentLocationTile());

    if (_suggestions.isNotEmpty) {
      items.add(const Divider(height: 1, thickness: 1));
      for (final result in _suggestions) {
        items.add(_buildSuggestionTile(result));
      }
    }

    final bgColor = widget.isDark ? AppColors.darkSurface : Colors.white;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: bgColor,
      surfaceTintColor: bgColor,
      shadowColor: Colors.black26,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 250,
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: items,
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    return InkWell(
      onTap: _onSelectCurrentLocation,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            Icon(
              Icons.near_me,
              size: 16,
              color: widget.isDark
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(LocationSearchResult result) {
    return InkWell(
      onTap: () => _onSelectResult(result),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 18,
                color: widget.isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.placeName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? AppColors.white : AppColors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
