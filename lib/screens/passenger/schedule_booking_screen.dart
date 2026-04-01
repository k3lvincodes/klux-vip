import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class ScheduleBookingScreen extends StatefulWidget {
  const ScheduleBookingScreen({super.key});

  @override
  State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  int _passengers = 1;

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
                  
                  // Date and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_today, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'Date and time',
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
                  _buildLocationInput(hint: 'From', iconColor: Colors.green),
                  const SizedBox(height: 12),
                  const Icon(Icons.arrow_downward, color: Colors.black, size: 24),
                  const SizedBox(height: 12),
                  _buildLocationInput(hint: 'To', iconColor: Colors.red),
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
                  CustomButton(
                    title: 'Find a driver',
                    onPress: () {
                      context.push('/trip-summary');
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
