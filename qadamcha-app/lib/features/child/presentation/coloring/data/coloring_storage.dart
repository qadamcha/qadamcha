import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coloring_image_data.dart';

class SavedArtwork {
  final String id;
  final String originalImageId;
  final String savedPath;
  final DateTime date;
  
  final String name;
  final String emoji;
  final String category;
  final int difficulty;

  SavedArtwork({
    required this.id,
    required this.originalImageId,
    required this.savedPath,
    required this.date,
    required this.name,
    required this.emoji,
    required this.category,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalImageId': originalImageId,
    'savedPath': savedPath,
    'date': date.toIso8601String(),
    'name': name,
    'emoji': emoji,
    'category': category,
    'difficulty': difficulty,
  };

  factory SavedArtwork.fromJson(Map<String, dynamic> json) => SavedArtwork(
    id: json['id'],
    originalImageId: json['originalImageId'],
    savedPath: json['savedPath'],
    date: DateTime.parse(json['date']),
    name: json['name'],
    emoji: json['emoji'],
    category: json['category'],
    difficulty: json['difficulty'],
  );
}

class ColoringStorage {
  static const String _artworksKey = 'saved_artworks';

  // ═══ PERFORMANCE: In-memory cache ═══
  static List<SavedArtwork>? _cachedArtworks;

  /// Rasmni galereyaga (app papkasiga) saqlash
  static Future<SavedArtwork?> saveImage(ui.Image image, ColoringImageInfo info) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final buffer = byteData.buffer.asUint8List();
      
      final dir = await getApplicationDocumentsDirectory();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${dir.path}/artwork_$id.png');
      
      await file.writeAsBytes(buffer);

      final artwork = SavedArtwork(
        id: id,
        originalImageId: info.id,
        savedPath: file.path,
        date: DateTime.now(),
        name: info.name,
        emoji: info.emoji,
        category: info.category,
        difficulty: info.difficulty,
      );

      final prefs = await SharedPreferences.getInstance();
      final artworksJson = prefs.getStringList(_artworksKey) ?? [];
      
      artworksJson.add(jsonEncode(artwork.toJson()));
      await prefs.setStringList(_artworksKey, artworksJson);

      // ═══ PERFORMANCE: Cache yangilash ═══
      _cachedArtworks = null;

      return artwork;
    } catch (e) {
      debugPrint('Xatolik: Rasmni saqlashda muammo: $e');
      return null;
    }
  }

  /// Barcha saqlangan rasmlarni olish — cached
  static Future<List<SavedArtwork>> getSavedArtworks() async {
    if (_cachedArtworks != null) return _cachedArtworks!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final artworksJson = prefs.getStringList(_artworksKey) ?? [];
      
      final artworks = artworksJson.map((jsonStr) {
        return SavedArtwork.fromJson(jsonDecode(jsonStr));
      }).toList();

      artworks.sort((a, b) => b.date.compareTo(a.date));
      _cachedArtworks = artworks;
      return artworks;
    } catch (e) {
      debugPrint('Xatolik saqlangan rasmlarni olishda: $e');
      return [];
    }
  }

  /// Rasmni o'chirish
  static Future<void> deleteArtwork(SavedArtwork artwork) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final artworksJson = prefs.getStringList(_artworksKey) ?? [];
      
      artworksJson.removeWhere((jsonStr) {
        final decoded = jsonDecode(jsonStr);
        return decoded['id'] == artwork.id;
      });
      
      await prefs.setStringList(_artworksKey, artworksJson);

      final file = File(artwork.savedPath);
      if (await file.exists()) {
        await file.delete();
      }

      // ═══ PERFORMANCE: Cache invalidate ═══
      _cachedArtworks = null;
    } catch (e) {
      debugPrint('Xatolik rasmni o\'chirishda: $e');
    }
  }

  /// Umuman bo'yalgan rasmlar soni
  static Future<int> getTotalCompleted() async {
    final artworks = await getSavedArtworks();
    return artworks.length;
  }

  /// Bo'yab bitkazilgan rasm ID'larini olish (yulduzcha uchun)
  static Future<Set<String>> getCompletedImageIds() async {
    final artworks = await getSavedArtworks();
    return artworks.map((a) => a.originalImageId).toSet();
  }
}
