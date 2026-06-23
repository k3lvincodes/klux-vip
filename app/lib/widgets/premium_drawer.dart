import 'package:flutter/material.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class PremiumDrawer extends StatelessWidget {

  const PremiumDrawer({
    super.key,
    required this.header,
    required this.items,
    this.footer,
    required this.isDark,
  });
  final Widget header;
  final List<Widget> items;
  final Widget? footer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBE5E4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              slideOffset: 0.04,
              child: header,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  for (int i = 0; i < items.length; i++)
                    FadeSlideIn(
                      delay: Duration(milliseconds: 120 + i * 50),
                      slideOffset: 0.03,
                      child: items[i],
                    ),
                ],
              ),
            ),
            if (footer != null)
              FadeSlideIn(
                delay: Duration(milliseconds: 120 + items.length * 50),
                slideOffset: 0.03,
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
