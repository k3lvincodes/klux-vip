import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({super.key});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          const GoogleMap(
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          
          Consumer<RideProvider>(
            builder: (context, rideProv, child) {
              final status = rideProv.currentRideDetails?['status'] ?? 'requested';
              final isSearching = status == 'requested';

              return Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSearching ? AppColors.white : Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isSearching ? null : Border.all(color: Colors.green),
                    ),
                    child: Text(
                      isSearching ? 'Searching for driver...' : 'Driver found!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSearching ? AppColors.black : Colors.green[800],
                      ),
                    ),
                  ),
                ),
              );
            }
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
                  const Text(
                    'Trip summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Number of passengers (Static display here)
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
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Location Inputs (Read-only styled)
                  Consumer<RideProvider>(
                    builder: (context, rideProv, child) {
                      final pickup = rideProv.currentRideDetails?['pickup_address'] ?? 'From';
                      final dropoff = rideProv.currentRideDetails?['dropoff_address'] ?? 'To';
                      return Column(
                        children: [
                          _buildLocationInput(hint: pickup, iconColor: Colors.green),
                          const SizedBox(height: 12),
                          const Icon(Icons.arrow_downward, color: Colors.black, size: 24),
                          const SizedBox(height: 12),
                          _buildLocationInput(hint: dropoff, iconColor: Colors.red),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 24),
                  
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
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
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
                  const SizedBox(height: 16),
                  
                  // Payment Method Row
                  GestureDetector(
                    onTap: () {
                      context.push('/payment-method');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Payment method',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black87),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Note text
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Note that payment validate order',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Done Button
                  CustomButton(
                    title: 'Done',
                    onPress: () {
                      // Finalize booking
                    },
                    variant: ButtonVariant.primary,
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

  Widget _buildLocationInput({required String hint, required Color iconColor}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.location_on, color: iconColor),
          const SizedBox(width: 12),
          Text(
            hint,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
