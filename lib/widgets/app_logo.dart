import 'package:flutter/material.dart';

/// Reusable app logo widget that can be used throughout the application
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showBackground = false,
    this.backgroundColor,
    this.borderRadius = 16,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'lib/utils/tasklogo.webp',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.purple,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.task_alt,
            size: size * 0.6,
            color: Colors.white,
          ),
        );
      },
    );

    if (showBackground || showShadow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: showBackground ? (backgroundColor ?? Colors.purple.withValues(alpha: 0.1)) : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: (backgroundColor ?? Colors.purple).withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: logoWidget,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: logoWidget,
    );
  }
}

/// Circular app logo for avatars and profile pictures
class CircularAppLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const CircularAppLogo({
    super.key,
    this.size = 56,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = ClipOval(
      child: Image.asset(
        'lib/utils/tasklogo.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt,
              size: size * 0.6,
              color: Colors.white,
            ),
          );
        },
      ),
    );

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.purple,
            width: borderWidth,
          ),
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}