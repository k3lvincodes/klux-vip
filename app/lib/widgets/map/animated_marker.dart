import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kenick_vip/theme/app_colors.dart';


class AnimatedMarker {
  static Marker bounceIn({
    required LatLng point,
    required Widget child,
    double width = 40,
    double height = 40,
    double? rotationAngle,
  }) {
    return Marker(
      point: point,
      width: width,
      height: height,
      rotate: true,
      child: _BounceInWrapper(
        child: rotationAngle != null
            ? Transform.rotate(angle: rotationAngle * pi / 180, child: child)
            : child,
      ),
    );
  }

  static Marker pulse({
    required LatLng point,
    required Color color,
    double size = 40,
    double pulseSize = 60,
  }) {
    return Marker(
      point: point,
      width: pulseSize,
      height: pulseSize,
      child: _PulseMarker(
        color: color,
        size: size,
        pulseSize: pulseSize,
      ),
    );
  }

  static Marker locationDot({
    required LatLng point,
    required Color color,
    double size = 40,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
      ),
    );
  }

  static Marker pickupPin({
    required LatLng point,
    String? label,
    bool animateOut = false,
  }) {
    return Marker(
      point: point,
      width: 48,
      height: 64,
      child: _AnimateOutPinWrapper(
        animateOut: animateOut,
        child: _BounceInWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: label != null
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : null,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: label != null
                    ? Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))
                    : const SizedBox(width: 16, height: 16),
              ),
              Transform.rotate(
                angle: pi,
                child: const Icon(Icons.arrow_drop_down,
                    color: Colors.green, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Marker dropoffPin({
    required LatLng point,
    String? label,
  }) {
    return Marker(
      point: point,
      width: 48,
      height: 64,
      child: _BounceInWrapper(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: label != null
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: label != null
                  ? Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))
                  : const SizedBox(width: 16, height: 16),
            ),
            Transform.rotate(
              angle: pi,
              child: const Icon(Icons.arrow_drop_down,
                  color: Colors.red, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  static Marker driverCar({
    required LatLng point,
    double rotationAngle = 0,
    double size = 40,
    bool isStationary = false,
  }) {
    return Marker(
      point: point,
      width: size * 2.2,
      height: size * 2.2,
      child: _DriverCarMarker(
        rotationAngle: rotationAngle,
        size: size,
        isStationary: isStationary,
      ),
    );
  }
}

class _AnimateOutPinWrapper extends StatefulWidget {
  final Widget child;
  final bool animateOut;

  const _AnimateOutPinWrapper({required this.child, required this.animateOut});

  @override
  State<_AnimateOutPinWrapper> createState() => _AnimateOutPinWrapperState();
}

class _AnimateOutPinWrapperState extends State<_AnimateOutPinWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimateOutPinWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateOut && !oldWidget.animateOut) {
      _controller.reverse();
    } else if (!widget.animateOut && oldWidget.animateOut) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _scale,
        child: widget.child,
      ),
    );
  }
}

class _DriverCarMarker extends StatefulWidget {
  final double rotationAngle;
  final double size;
  final bool isStationary;

  const _DriverCarMarker({
    required this.rotationAngle,
    required this.size,
    required this.isStationary,
  });

  @override
  State<_DriverCarMarker> createState() => _DriverCarMarkerState();
}

class _DriverCarMarkerState extends State<_DriverCarMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _bounceController;
  late final Animation<double> _pulse;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.8, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bounce = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOutSine),
    );

    if (widget.isStationary) {
      _pulseController.repeat();
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _DriverCarMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStationary && !oldWidget.isStationary) {
      _pulseController.repeat();
      _bounceController.repeat(reverse: true);
    } else if (!widget.isStationary && oldWidget.isStationary) {
      _pulseController.stop();
      _bounceController.stop();
      _bounceController.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radAngle = widget.rotationAngle * pi / 180;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Radar Effect
        if (widget.isStationary)
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final opacity = (2.0 - _pulse.value).clamp(0.0, 1.0) * 0.4;
              return Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: opacity),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: opacity * 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

        // Main Car Marker (with subtle idle bounce)
        AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, widget.isStationary ? _bounce.value : 0.0),
              child: child,
            );
          },
          child: Transform.rotate(
            angle: radAngle,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: const Color(0xFF18151A), // Sleek metallic black VIP background
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.navigation, // oriented straight up for correct rotation
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _BounceInWrapper extends StatefulWidget {
  final Widget child;

  const _BounceInWrapper({required this.child});

  @override
  State<_BounceInWrapper> createState() => _BounceInWrapperState();
}

class _BounceInWrapperState extends State<_BounceInWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: widget.child,
    );
  }
}

class _PulseMarker extends StatefulWidget {
  final Color color;
  final double size;
  final double pulseSize;

  const _PulseMarker({
    required this.color,
    required this.size,
    required this.pulseSize,
  });

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1 + (widget.pulseSize / widget.size - 1) * _pulse.value;
        final opacity = 1 - _pulse.value * 0.5;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
