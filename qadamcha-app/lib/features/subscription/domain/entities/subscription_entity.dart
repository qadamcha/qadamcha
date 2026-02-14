import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    this.paymentMethod,
    required this.createdAt,
  });

  bool get isActive =>
      status == SubscriptionStatus.active &&
      DateTime.now().isBefore(endDate);

  bool get isPremium =>
      isActive && plan != SubscriptionPlan.monthly;

  int get remainingDays {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  @override
  List<Object?> get props => [id, plan, status, startDate, endDate];
}

enum SubscriptionPlan {
  monthly('monthly', 'Oylik', 49000, '⭐'),
  yearly('yearly', 'Yillik', 399000, '💎'),
  lifetime('lifetime', 'Umrbod', 990000, '👨‍👩‍👧‍👦');

  final String value;
  final String label;
  final int priceUzs;
  final String emoji;

  const SubscriptionPlan(this.value, this.label, this.priceUzs, this.emoji);

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionPlan.monthly,
    );
  }

  String get formattedPrice {
    final thousands = (priceUzs / 1000).toStringAsFixed(0);
    switch (this) {
      case SubscriptionPlan.monthly:
        return '$thousands 000 so\'m/oy';
      case SubscriptionPlan.yearly:
        return '$thousands 000 so\'m/yil';
      case SubscriptionPlan.lifetime:
        return '$thousands 000 so\'m';
    }
  }

  String get periodLabel {
    switch (this) {
      case SubscriptionPlan.monthly:
        return '30 kun';
      case SubscriptionPlan.yearly:
        return '365 kun';
      case SubscriptionPlan.lifetime:
        return 'Cheksiz';
    }
  }
}

enum SubscriptionStatus {
  active('active', 'Faol'),
  cancelled('cancelled', 'Bekor qilingan'),
  expired('expired', 'Muddati o\'tgan'),
  pending('pending', 'Kutilmoqda'),
  failed('failed', 'Muvaffaqiyatsiz');

  final String value;
  final String label;

  const SubscriptionStatus(this.value, this.label);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionStatus.pending,
    );
  }
}

class PlanFeature extends Equatable {
  final String title;
  final String description;
  final bool included;

  const PlanFeature({
    required this.title,
    required this.description,
    required this.included,
  });

  @override
  List<Object?> get props => [title, included];
}

class PlanFeatures {
  static const Map<SubscriptionPlan, List<PlanFeature>> features = {
    SubscriptionPlan.monthly: [
      PlanFeature(title: 'Reklama yo\'q', description: 'Toza kontentlar', included: true),
      PlanFeature(title: '3 ta qurilma', description: '', included: true),
      PlanFeature(title: 'Barcha kontentlar', description: '', included: true),
      PlanFeature(title: 'AI maslahatchi', description: '', included: true),
      PlanFeature(title: 'Vaqt boshqaruvi', description: '', included: true),
    ],
    SubscriptionPlan.yearly: [
      PlanFeature(title: 'Reklama yo\'q', description: '', included: true),
      PlanFeature(title: '3 ta qurilma', description: '', included: true),
      PlanFeature(title: 'Barcha kontentlar', description: '', included: true),
      PlanFeature(title: 'AI maslahatchi', description: '', included: true),
      PlanFeature(title: 'Vaqt boshqaruvi', description: '', included: true),
      PlanFeature(title: '32% tejash', description: 'Oyligiga nisbatan', included: true),
    ],
    SubscriptionPlan.lifetime: [
      PlanFeature(title: 'Reklama yo\'q', description: '', included: true),
      PlanFeature(title: '3 ta qurilma', description: '', included: true),
      PlanFeature(title: 'Barcha kontentlar', description: '', included: true),
      PlanFeature(title: 'AI maslahatchi', description: '', included: true),
      PlanFeature(title: 'Vaqt boshqaruvi', description: '', included: true),
      PlanFeature(title: 'Umrbod foydalanish', description: 'Bir marta to\'lang', included: true),
    ],
  };
}
