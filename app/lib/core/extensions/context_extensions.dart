import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension BuildContextExtensions on BuildContext {
  // Navigation
  void pushRoute(String path) => GoRouter.of(this).push(path);
  void replaceRoute(String path) => GoRouter.of(this).pushReplacement(path);
  void popRoute() => GoRouter.of(this).pop();

  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Media
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;

  // Spacing helpers
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;
}
