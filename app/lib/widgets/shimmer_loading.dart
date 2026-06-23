import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShimmerLoading extends StatelessWidget {

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: isDark ? Colors.grey.shade700 : Colors.white60,
          angle: 0.5,
        );
  }
}

class ShimmerText extends StatelessWidget {

  const ShimmerText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 4,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class ShimmerCircle extends StatelessWidget {

  const ShimmerCircle({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }
}

class ShimmerCard extends StatelessWidget {

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.borderRadius = 16,
  });
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class ShimmerListItem extends StatelessWidget {

  const ShimmerListItem({
    super.key,
    this.height = 72,
    this.showAvatar = true,
    this.avatarSize = 40,
  });
  final double height;
  final bool showAvatar;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showAvatar) ...[
          ShimmerCircle(size: avatarSize),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerText(width: 140),
              SizedBox(height: 8),
              ShimmerText(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class ShimmerList extends StatelessWidget {

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.showAvatar = true,
    this.avatarSize = 40,
  });
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final bool showAvatar;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        if (showAvatar) {
          return ShimmerListItem(
            height: itemHeight,
            avatarSize: avatarSize,
          );
        }
        return ShimmerLoading(
          width: double.infinity,
          height: itemHeight,
          borderRadius: 16,
        );
      },
    );
  }
}
