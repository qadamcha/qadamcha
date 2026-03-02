import 'package:flutter/material.dart';

class AppColors {
  // === PRIMARY COLORS FROM DESIGN ===
  // Main Blue (Buttons, Links)
  static const Color primary = Color(0xFF2D6A9F);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF1A4A73);
  
  // Purple (Child mode, accents)
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleLight = Color(0xFFB388FF);
  static const Color purpleDark = Color(0xFF651FFF);
  
  // Pink (Child mode gradient)
  static const Color pink = Color(0xFFFF4081);
  static const Color pinkLight = Color(0xFFFF80AB);
  
  // Orange (Quests, warnings)
  static const Color orange = Color(0xFFFF6D00);
  static const Color orangeLight = Color(0xFFFF9E40);
  
  // Gold (Subscription, premium)
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  
  // Green (Success, active)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF00C853);
  
  // Red (Error, warnings)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  
  // === PAYMENT METHOD COLORS ===
  static const Color payme = Color(0xFF00CCCC);
  static const Color click = Color(0xFF3366FF);
  static const Color uzumBank = Color(0xFF7B2FBE);
  
  // === NEUTRAL COLORS ===
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Dark Theme
  static const Color darkBackground = Color(0xFF0F0F12);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  // === GRADIENTS ===
  
  // Splash Screen Gradient
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A4A73), Color(0xFF2D6A9F), Color(0xFF4A90D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  // Primary Blue Gradient (Buttons)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gold Gradient (Premium, Subscription)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Red Gradient (Error, Danger)
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Child Mode Gradient (Purple-Pink)
  static const LinearGradient childGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  // Child Home Background
  static const LinearGradient childHomeGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF), Color(0xFFF3E5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
  );
  
  // Content Card Gradients
  static const LinearGradient cartoonGradient = LinearGradient(
    colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient questGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9E40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gamesGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient storiesGradient = LinearGradient(
    colors: [Color(0xFF651FFF), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Expired Subscription Gradient
  static const LinearGradient expiredGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9E40), Color(0xFFFFF3E0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
  );
  
  // AI Chat Gradient
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sunset Gradient (Orange-Pink for premium features)
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Ocean Gradient (Blue-Teal)
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF2D6A9F), Color(0xFF00CCCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // === KID-FRIENDLY COLORS ===
  static const Color kidBlue = Color(0xFF4A90D9);
  static const Color kidGreen = Color(0xFF22C55E);
  static const Color kidPurple = Color(0xFF7C4DFF);
  static const Color kidYellow = Color(0xFFF59E0B);
  static const Color kidPink = Color(0xFFFF4081);
  static const Color kidOrange = Color(0xFFFF6D00);
  
  // Info color (for info badges)
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  
  // Secondary color alias
  static const Color secondary = Color(0xFFFF6D00);
  static const Color secondaryLight = Color(0xFFFF9E40);

  // Dark theme variants
  static const Color darkSurfaceVariant = Color(0xFF2A2A3E);

  // === BUBBLE WORLD 3D THEME ===
  
  // Bubble World Background Colors
  static const Color bubbleBgTop = Color(0xFFD6E6F5);       // Soft sky blue
  static const Color bubbleBgMid = Color(0xFFE4D9F0);       // Lavender
  static const Color bubbleBgBottom = Color(0xFFF8F4FF);    // Almost white purple
  
  // Bubble colors
  static const Color bubblePink = Color(0xFFFF99CC);
  static const Color bubbleBlue = Color(0xFF99CCFF);
  static const Color bubblePurple = Color(0xFFCC99FF);
  static const Color bubbleMint = Color(0xFF99FFE0);
  static const Color bubbleYellow = Color(0xFFFFE599);
  
  // 3D Card border gradient colors
  static const Color bubble3dPurple = Color(0xFF9B59B6);
  static const Color bubble3dBlue = Color(0xFF3498DB);
  static const Color bubble3dPink = Color(0xFFE91E8C);
  
  // Sparkle
  static const Color sparkleGold = Color(0xFFFFD700);
  static const Color sparkleWhite = Color(0xFFFFFFF0);
  
  // Bubble World Background Gradient
  static const LinearGradient bubbleWorldBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD6E6F5), Color(0xFFE4D9F0), Color(0xFFF8F4FF)],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Bubble NavBar Gradient
  static const LinearGradient bubbleNavBarGradient = LinearGradient(
    colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Bubble NavBar Selected Tab
  static const LinearGradient bubbleNavSelectedGradient = LinearGradient(
    colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Bubble Video Card Border
  static const LinearGradient bubbleCardBorderGradient = LinearGradient(
    colors: [Color(0xFF9B59B6), Color(0xFF3498DB), Color(0xFFE91E8C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  // Bubble Game Card Gradients
  static const LinearGradient bubbleMathGradient = LinearGradient(
    colors: [Color(0xFF9B59B6), Color(0xFFB07CD8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubbleAlphabetGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9A76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubblePuzzleGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF58D68D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubbleColorsGradient = LinearGradient(
    colors: [Color(0xFFE91E8C), Color(0xFFFF69B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubbleMusicGradient = LinearGradient(
    colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubbleGeoGradient = LinearGradient(
    colors: [Color(0xFF1ABC9C), Color(0xFF48C9B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

