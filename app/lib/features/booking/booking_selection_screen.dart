import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class BookingSelectionScreen extends StatelessWidget {
  const BookingSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header like My Profile
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Book a Ride',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),

              const Spacer(),

              // Buttons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    CustomButton(
                      title: 'Instant Booking',
                      onPress: () {
                        context.push('/instant-booking');
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: 'Schedule Booking',
                      onPress: () {
                        context.push('/schedule-booking');
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: 'Special Booking Request',
                      onPress: () {
                        context.push('/special-booking');
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
