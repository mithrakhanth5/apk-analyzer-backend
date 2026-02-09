/// Premium dark theme with purple/pink gradients and glassmorphism
/// Inspired by modern trading platform aesthetics

import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  AppTheme._();
  
  // Primary Gradient Colors
  static const Color primaryDark = Color(0xFF0D0D1A);      // Deep navy
  static const Color primaryMid = Color(0xFF1A1A2E);       // Dark purple-navy
  static const Color primaryLight = Color(0xFF16213E);     // Lighter navy
  
  // Accent Colors - Vibrant Pink/Purple
  static const Color accentPink = Color(0xFFE94560);       // Coral pink
  static const Color accentPinkLight = Color(0xFFFF6B9D);  // Light pink
  static const Color accentPurple = Color(0xFF7B2CBF);     // Deep purple
  static const Color accentCyan = Color(0xFF00D9FF);       // Cyan glow
  
  // Risk Level Colors
  static const Color safeColor = Color(0xFF00E676);        // Neon green
  static const Color suspiciousColor = Color(0xFFFFAB40);  // Orange
  static const Color highRiskColor = Color(0xFFFF5252);    // Red
  static const Color criticalColor = Color(0xFFE040FB);    // Magenta
  
  // Background Colors
  static const Color backgroundColor = Color(0xFF0D0D1A);
  static const Color surfaceColor = Color(0xFF1A1A2E);
  static const Color cardColor = Color(0xFF252542);
  
  // Glassmorphism Colors
  static const Color glassColor = Color(0x1AFFFFFF);       // 10% white
  static const Color glassBorder = Color(0x33FFFFFF);      // 20% white border
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D0);
  static const Color textMuted = Color(0xFF6E6E8A);
  
  // Status Colors
  static const Color infoColor = Color(0xFF29B6F6);
  static const Color warningColor = Color(0xFFFFAB40);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF00E676);
  
  /// Primary gradient for backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D0D1A),
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
    ],
  );
  
  /// Accent gradient for buttons and highlights
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE94560),
      Color(0xFFFF6B9D),
    ],
  );
  
  /// Purple accent gradient
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B2CBF),
      Color(0xFFE94560),
    ],
  );
  
  /// Get color for risk classification
  static Color getRiskColor(String classification) {
    switch (classification.toUpperCase()) {
      case 'SAFE':
        return safeColor;
      case 'SUSPICIOUS':
        return suspiciousColor;
      case 'HIGH_RISK':
        return highRiskColor;
      default:
        return textSecondary;
    }
  }
  
  /// Get color for risk score
  static Color getScoreColor(int score) {
    if (score <= 30) return safeColor;
    if (score <= 60) return suspiciousColor;
    return highRiskColor;
  }
  
  /// Get severity color
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return criticalColor;
      case 'HIGH':
        return highRiskColor;
      case 'MEDIUM':
        return suspiciousColor;
      case 'LOW':
        return infoColor;
      default:
        return textSecondary;
    }
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: accentPink,
        secondary: accentPurple,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: glassColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: accentPink.withOpacity(0.4),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: glassBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPink,
        ),
      ),
      
      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: accentPink,
        unselectedLabelColor: textMuted,
        indicatorColor: accentPink,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      
      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: glassBorder,
        thickness: 1,
      ),
      
      // Icon
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentPink,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

/// Custom text styles
class AppTextStyles {
  AppTextStyles._();
  
  static const TextStyle riskScore = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
  );
  
  static const TextStyle classification = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );
  
  static const TextStyle findingTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle permissionName = TextStyle(
    fontSize: 13,
    fontFamily: 'monospace',
    letterSpacing: -0.5,
  );
}

/// Glassmorphic card widget
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double blur;
  
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.blur = 10,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient background widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  
  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? const [
            Color(0xFF0D0D1A),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative gradient orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPink.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Gradient button widget
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  
  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPink.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
