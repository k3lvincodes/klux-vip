import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/auth_provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';

class InstantBookingScreen extends StatefulWidget {
  const InstantBookingScreen({super.key});

  @override
  State<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingScreenState extends State<InstantBookingScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  int _passengers = 1;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  Future<void> _handleFindDriver() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter pickup and dropoff locations')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();

    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    final success = await rideProvider.requestInstantRide(
      passengerId: auth.currentUser!.id,
      pickupAddress: _fromController.text,
      dropoffAddress: _toController.text,
    );

    if (success && mounted) {
      context.push('/trip-summary');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rideProvider.errorMessage ?? 'Failed to request ride')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          const GoogleMap(
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios, color: AppColors.black, size: 28),
            ),
          ),
          
          // Bottom Sheet / Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFEBE5E4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Number of passengers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'Number of passengers',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$_passengers',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _passengers++),
                                  child: const Icon(Icons.keyboard_arrow_up, size: 16),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (_passengers > 1) setState(() => _passengers--);
                                  },
                                  child: const Icon(Icons.keyboard_arrow_down, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Comments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.comment, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black87),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Location Inputs
                  _buildLocationInput(hint: 'From', iconColor: Colors.green, controller: _fromController),
                  const SizedBox(height: 12),
                  const Icon(Icons.arrow_downward, color: Colors.black, size: 24),
                  const SizedBox(height: 12),
                  _buildLocationInput(hint: 'To', iconColor: Colors.red, controller: _toController),
                  const SizedBox(height: 32),
                  
                  // Fare Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBE5E4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '\$200',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Total fare',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Find Driver Button
                  Consumer<RideProvider>(
                    builder: (context, rideProv, child) {
                      return CustomButton(
                        title: rideProv.isLoading ? 'Requesting...' : 'Find a driver',
                        onPress: rideProv.isLoading ? () {} : _handleFindDriver,
                        variant: ButtonVariant.primary,
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({required String hint, required Color iconColor, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.location_on, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              style: const TextStyle(color: AppColors.black, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
