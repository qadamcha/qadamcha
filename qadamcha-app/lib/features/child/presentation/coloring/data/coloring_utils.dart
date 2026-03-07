import 'package:flutter/material.dart';

/// Coloring moduli uchun umumiy yordamchi funksiyalar.
/// Barcha fayallarda takrorlanuvchi category color/emoji
/// funksiyalarini bitta joyda saqlaydi (DRY printsip).
class ColoringUtils {
  ColoringUtils._(); // Instance yaratishni oldini olish

  /// Kategoriya nomi bo'yicha rang qaytarish
  static Color categoryColor(String category) {
    switch (category) {
      case 'Hayvonlar':
        return const Color(0xFFF97316); // Orange
      case 'Mashinalar':
        return const Color(0xFF3B82F6); // Blue
      case 'Mevalar':
        return const Color(0xFFEF4444); // Red
      case 'Tabiat':
        return const Color(0xFF22C55E); // Green
      case 'Poliz Mevalari':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Kategoriya nomi bo'yicha emoji qaytarish
  static String categoryEmoji(String category) {
    switch (category) {
      case 'Hayvonlar':
        return '🐾';
      case 'Mashinalar':
        return '🚗';
      case 'Mevalar':
        return '🍎';
      case 'Tabiat':
        return '🌿';
      case 'Poliz Mevalari':
        return '🥬';
      default:
        return '📁';
    }
  }
}
