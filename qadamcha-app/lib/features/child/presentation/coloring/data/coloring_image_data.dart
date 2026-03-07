import 'package:flutter/material.dart';

/// Bo'yash uchun rasm ma'lumotlari
class ColoringImageInfo {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String assetPath;
  final int difficulty; // 1=oson, 2=o'rta, 3=qiyin

  const ColoringImageInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.assetPath,
    required this.difficulty,
  });
}

/// O'yin uchun ranglar palitrasi
class ColoringPalette {
  static const List<Color> colors = [
    // Qizillar
    Color(0xFFFF1744), // Qizil
    Color(0xFFD50000), // To'q qizil
    Color(0xFFFF8A80), // Och qizil

    // Pushtilar
    Color(0xFFFF4081), // Pushti
    Color(0xFFF48FB1), // Och pushti
    Color(0xFFC2185B), // To'q pushti

    // To'q sariqlar
    Color(0xFFFF9100), // To'q sariq
    Color(0xFFFFCC80), // Och to'q sariq
    
    // Sariqlar
    Color(0xFFFFEA00), // Sariq
    Color(0xFFFFF9C4), // Och sariq

    // Yashillar
    Color(0xFF00E676), // Yashil
    Color(0xFF388E3C), // To'q yashil
    Color(0xFFA5D6A7), // Och yashil

    // Ko'klar
    Color(0xFF2979FF), // Ko'k
    Color(0xFF0D47A1), // To'q ko'k
    Color(0xFF90CAF9), // Och ko'k
    Color(0xFF00BCD4), // Havorang

    // Binafshalar
    Color(0xFFD500F9), // Binafsha
    Color(0xFF7B1FA2), // To'q binafsha
    Color(0xFFCE93D8), // Och binafsha

    // Tabiiy ranglar
    Color(0xFF795548), // Jigarrang
    Color(0xFFA1887F), // Och jigarrang
    Color(0xFF212121), // Qora
    Color(0xFF9E9E9E), // Kulrang
    Color(0xFFFAFAFA), // Oq
  ];

  static const List<String> colorNames = [
    'Qizil', 'To\'q qizil', 'Och qizil',
    'Pushti', 'Och pushti', 'To\'q pushti',
    'To\'q sariq', 'Och to\'q sariq',
    'Sariq', 'Och sariq',
    'Yashil', 'To\'q yashil', 'Och yashil',
    'Ko\'k', 'To\'q ko\'k', 'Och ko\'k', 'Havorang',
    'Binafsha', 'To\'q binafsha', 'Och binafsha',
    'Jigarrang', 'Och jigarrang', 'Qora', 'Kulrang', 'Oq',
  ];
}

/// 4 ta kategoriya: Hayvonlar, Mashinalar, Mevalar, Tabiat
class ColoringImages {
  // ═══ PERFORMANCE: Lazy singleton cache ═══
  static List<ColoringImageInfo>? _allCache;
  static final Map<String, List<ColoringImageInfo>> _categoryCache = {};

  static List<ColoringImageInfo> all() => _allCache ??= const [
        // ═══════════════════════════════════════
        // 🐾 HAYVONLAR (14 ta)
        // ═══════════════════════════════════════
        ColoringImageInfo(id: 'cat', name: 'Mushuk', emoji: '🐱', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/cat.png', difficulty: 1),
        ColoringImageInfo(id: 'dog', name: 'It', emoji: '🐶', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/dog.png', difficulty: 1),
        ColoringImageInfo(id: 'elephant', name: 'Fil', emoji: '🐘', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/elephant.png', difficulty: 2),
        ColoringImageInfo(id: 'butterfly', name: 'Kapalak', emoji: '🦋', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/butterfly.png', difficulty: 1),
        ColoringImageInfo(id: 'rabbit', name: 'Quyon', emoji: '🐰', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/rabbit.png', difficulty: 1),
        ColoringImageInfo(id: 'lion', name: 'Sher', emoji: '🦁', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/lion.png', difficulty: 2),
        ColoringImageInfo(id: 'fish', name: 'Baliq', emoji: '🐟', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/fish.png', difficulty: 1),
        ColoringImageInfo(id: 'bird', name: 'Qush', emoji: '🐦', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/bird.png', difficulty: 1),
        ColoringImageInfo(id: 'turtle', name: 'Toshbaqa', emoji: '🐢', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/turtle.png', difficulty: 2),
        ColoringImageInfo(id: 'horse', name: 'Ot', emoji: '🐴', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/horse.png', difficulty: 2),
        ColoringImageInfo(id: 'penguin', name: 'Pingvin', emoji: '🐧', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/penguin.png', difficulty: 1),
        ColoringImageInfo(id: 'frog', name: 'Baqa', emoji: '🐸', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/frog.png', difficulty: 1),
        ColoringImageInfo(id: 'bear', name: 'Ayiq', emoji: '🐻', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/bear.png', difficulty: 2),
        ColoringImageInfo(id: 'owl', name: 'Boyqush', emoji: '🦉', category: 'Hayvonlar', assetPath: 'assets/coloring_pages/owl.png', difficulty: 2),

        // ═══════════════════════════════════════
        // 🚗 MASHINALAR (15 ta)
        // ═══════════════════════════════════════
        ColoringImageInfo(id: 'car', name: 'Mashina', emoji: '🚗', category: 'Mashinalar', assetPath: 'assets/coloring_pages/car.png', difficulty: 1),
        ColoringImageInfo(id: 'truck', name: 'Yuk mashina', emoji: '🚛', category: 'Mashinalar', assetPath: 'assets/coloring_pages/truck.png', difficulty: 2),
        ColoringImageInfo(id: 'bus', name: 'Avtobus', emoji: '🚌', category: 'Mashinalar', assetPath: 'assets/coloring_pages/bus.png', difficulty: 2),
        ColoringImageInfo(id: 'airplane', name: 'Samolyot', emoji: '✈️', category: 'Mashinalar', assetPath: 'assets/coloring_pages/airplane.png', difficulty: 2),
        ColoringImageInfo(id: 'train', name: 'Poyezd', emoji: '🚂', category: 'Mashinalar', assetPath: 'assets/coloring_pages/train.png', difficulty: 2),
        ColoringImageInfo(id: 'helicopter', name: 'Vertolyot', emoji: '🚁', category: 'Mashinalar', assetPath: 'assets/coloring_pages/helicopter.png', difficulty: 2),
        ColoringImageInfo(id: 'motorcycle', name: 'Mototsikl', emoji: '🏍️', category: 'Mashinalar', assetPath: 'assets/coloring_pages/motorcycle.png', difficulty: 2),
        ColoringImageInfo(id: 'bicycle', name: 'Velosiped', emoji: '🚲', category: 'Mashinalar', assetPath: 'assets/coloring_pages/bicycle.png', difficulty: 1),
        ColoringImageInfo(id: 'rocket', name: 'Raketa', emoji: '🚀', category: 'Mashinalar', assetPath: 'assets/coloring_pages/rocket.png', difficulty: 1),
        ColoringImageInfo(id: 'ship', name: 'Kema', emoji: '⛵', category: 'Mashinalar', assetPath: 'assets/coloring_pages/ship.png', difficulty: 2),
        ColoringImageInfo(id: 'firetruck', name: 'O\'t o\'chirish', emoji: '🚒', category: 'Mashinalar', assetPath: 'assets/coloring_pages/firetruck.png', difficulty: 2),
        ColoringImageInfo(id: 'tractor', name: 'Traktor', emoji: '🚜', category: 'Mashinalar', assetPath: 'assets/coloring_pages/tractor.png', difficulty: 2),
        ColoringImageInfo(id: 'ambulance', name: 'Tez yordam', emoji: '🚑', category: 'Mashinalar', assetPath: 'assets/coloring_pages/ambulance.png', difficulty: 1),
        ColoringImageInfo(id: 'submarine', name: 'Suv osti kemasi', emoji: '🚢', category: 'Mashinalar', assetPath: 'assets/coloring_pages/submarine.png', difficulty: 2),
        ColoringImageInfo(id: 'policecar', name: 'Politsiya', emoji: '🚔', category: 'Mashinalar', assetPath: 'assets/coloring_pages/policecar.png', difficulty: 1),

        // ═══════════════════════════════════════
        // 🍎 MEVALAR (15 ta)
        // ═══════════════════════════════════════
        ColoringImageInfo(id: 'apple', name: 'Olma', emoji: '🍎', category: 'Mevalar', assetPath: 'assets/coloring_pages/apple.png', difficulty: 1),
        ColoringImageInfo(id: 'banana', name: 'Banan', emoji: '🍌', category: 'Mevalar', assetPath: 'assets/coloring_pages/banana.png', difficulty: 1),
        ColoringImageInfo(id: 'strawberry', name: 'Qulupnay', emoji: '🍓', category: 'Mevalar', assetPath: 'assets/coloring_pages/strawberry.png', difficulty: 1),
        ColoringImageInfo(id: 'watermelon', name: 'Tarvuz', emoji: '🍉', category: 'Mevalar', assetPath: 'assets/coloring_pages/watermelon.png', difficulty: 1),
        ColoringImageInfo(id: 'grapes', name: 'Uzum', emoji: '🍇', category: 'Mevalar', assetPath: 'assets/coloring_pages/grapes.png', difficulty: 2),
        ColoringImageInfo(id: 'pear', name: 'Nok', emoji: '🍐', category: 'Mevalar', assetPath: 'assets/coloring_pages/pear.png', difficulty: 1),
        ColoringImageInfo(id: 'pineapple', name: 'Ananas', emoji: '🍍', category: 'Mevalar', assetPath: 'assets/coloring_pages/pineapple.png', difficulty: 2),
        ColoringImageInfo(id: 'peach', name: 'Shaftoli', emoji: '🍑', category: 'Mevalar', assetPath: 'assets/coloring_pages/peach.png', difficulty: 1),
        ColoringImageInfo(id: 'lemon', name: 'Limon', emoji: '🍋', category: 'Mevalar', assetPath: 'assets/coloring_pages/lemon.png', difficulty: 1),
        ColoringImageInfo(id: 'pomegranate', name: 'Anor', emoji: '🫐', category: 'Mevalar', assetPath: 'assets/coloring_pages/pomegranate.png', difficulty: 2),
        ColoringImageInfo(id: 'mango', name: 'Mango', emoji: '🥭', category: 'Mevalar', assetPath: 'assets/coloring_pages/mango.png', difficulty: 1),
        ColoringImageInfo(id: 'plum', name: 'Olxo\'ri', emoji: '🟣', category: 'Mevalar', assetPath: 'assets/coloring_pages/plum.png', difficulty: 1),
        ColoringImageInfo(id: 'coconut', name: 'Ko\'knor', emoji: '🥥', category: 'Mevalar', assetPath: 'assets/coloring_pages/coconut.png', difficulty: 2),
        ColoringImageInfo(id: 'avocado', name: 'Avokado', emoji: '🥑', category: 'Mevalar', assetPath: 'assets/coloring_pages/avocado.png', difficulty: 1),
        ColoringImageInfo(id: 'fig', name: 'Anjir', emoji: '🫐', category: 'Mevalar', assetPath: 'assets/coloring_pages/fig.png', difficulty: 1),

        // ═══════════════════════════════════════
        // 🌿 TABIAT (15 ta)
        // ═══════════════════════════════════════
        ColoringImageInfo(id: 'sun', name: 'Quyosh', emoji: '☀️', category: 'Tabiat', assetPath: 'assets/coloring_pages/sun.png', difficulty: 1),
        ColoringImageInfo(id: 'tree', name: 'Daraxt', emoji: '🌳', category: 'Tabiat', assetPath: 'assets/coloring_pages/tree.png', difficulty: 1),
        ColoringImageInfo(id: 'rose', name: 'Atirgul', emoji: '🌹', category: 'Tabiat', assetPath: 'assets/coloring_pages/rose.png', difficulty: 2),
        ColoringImageInfo(id: 'cloud', name: 'Bulut', emoji: '🌧️', category: 'Tabiat', assetPath: 'assets/coloring_pages/cloud.png', difficulty: 1),
        ColoringImageInfo(id: 'rainbow', name: 'Kamalak', emoji: '🌈', category: 'Tabiat', assetPath: 'assets/coloring_pages/rainbow.png', difficulty: 2),
        ColoringImageInfo(id: 'volcano', name: 'Vulqon', emoji: '🌋', category: 'Tabiat', assetPath: 'assets/coloring_pages/volcano.png', difficulty: 2),
        ColoringImageInfo(id: 'mushroom', name: 'Qo\'ziqorin', emoji: '🍄', category: 'Tabiat', assetPath: 'assets/coloring_pages/mushroom.png', difficulty: 1),
        ColoringImageInfo(id: 'star', name: 'Yulduz', emoji: '⭐', category: 'Tabiat', assetPath: 'assets/coloring_pages/star.png', difficulty: 1),
        ColoringImageInfo(id: 'moon', name: 'Oy', emoji: '🌙', category: 'Tabiat', assetPath: 'assets/coloring_pages/moon.png', difficulty: 1),
        ColoringImageInfo(id: 'snowflake', name: 'Qor parchasi', emoji: '❄️', category: 'Tabiat', assetPath: 'assets/coloring_pages/snowflake.png', difficulty: 2),
        ColoringImageInfo(id: 'cactus', name: 'Kaktus', emoji: '🌵', category: 'Tabiat', assetPath: 'assets/coloring_pages/cactus.png', difficulty: 1),
        ColoringImageInfo(id: 'leaf', name: 'Barg', emoji: '🍃', category: 'Tabiat', assetPath: 'assets/coloring_pages/leaf.png', difficulty: 1),
        ColoringImageInfo(id: 'seashell', name: 'Chig\'anoq', emoji: '🐚', category: 'Tabiat', assetPath: 'assets/coloring_pages/seashell.png', difficulty: 2),
        ColoringImageInfo(id: 'tulip', name: 'Lola', emoji: '🌷', category: 'Tabiat', assetPath: 'assets/coloring_pages/tulip.png', difficulty: 1),
        ColoringImageInfo(id: 'palmtree', name: 'Palma', emoji: '🌴', category: 'Tabiat', assetPath: 'assets/coloring_pages/palmtree.png', difficulty: 2),

        // ═══════════════════════════════════════
        // 🥬 POLIZ MEVALARI (14 ta)
        // ═══════════════════════════════════════
        ColoringImageInfo(id: 'tomato', name: 'Pomidor', emoji: '🍅', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/tomato.png', difficulty: 1),
        ColoringImageInfo(id: 'carrot', name: 'Sabzi', emoji: '🥕', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/carrot.png', difficulty: 1),
        ColoringImageInfo(id: 'cucumber', name: 'Bodring', emoji: '🥒', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/cucumber.png', difficulty: 1),
        ColoringImageInfo(id: 'pumpkin', name: 'Qovoq', emoji: '🎃', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/pumpkin.png', difficulty: 2),
        ColoringImageInfo(id: 'pepper', name: 'Qalampir', emoji: '🫑', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/pepper.png', difficulty: 1),
        ColoringImageInfo(id: 'eggplant', name: 'Baqlajon', emoji: '🍆', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/eggplant.png', difficulty: 1),
        ColoringImageInfo(id: 'cabbage', name: 'Karam', emoji: '🥬', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/cabbage.png', difficulty: 2),
        ColoringImageInfo(id: 'onion', name: 'Piyoz', emoji: '🧅', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/onion.png', difficulty: 1),
        ColoringImageInfo(id: 'potato', name: 'Kartoshka', emoji: '🥔', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/potato.png', difficulty: 1),
        ColoringImageInfo(id: 'corn', name: 'Makkajo\'xori', emoji: '🌽', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/corn.png', difficulty: 2),
        ColoringImageInfo(id: 'peas', name: 'No\'xat', emoji: '🟢', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/peas.png', difficulty: 1),
        ColoringImageInfo(id: 'beet', name: 'Lavlagi', emoji: '🟣', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/beet.png', difficulty: 2),
        ColoringImageInfo(id: 'garlic', name: 'Sarimsoq', emoji: '🧄', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/garlic.png', difficulty: 1),
        ColoringImageInfo(id: 'hotpepper', name: 'Achchiq qalampir', emoji: '🌶️', category: 'Poliz Mevalari', assetPath: 'assets/coloring_pages/hotpepper.png', difficulty: 1),
      ];

  /// Kategoriyalar ro'yxati (belgilangan tartibda)
  static List<String> categories() {
    return ['Hayvonlar', 'Mashinalar', 'Mevalar', 'Tabiat', 'Poliz Mevalari'];
  }

  /// Kategoriya bo'yicha filter — cached
  static List<ColoringImageInfo> byCategory(String category) {
    return _categoryCache[category] ??=
        all().where((img) => img.category == category).toList();
  }
}
