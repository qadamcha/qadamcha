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
      isActive && 
      (plan == SubscriptionPlan.premium || plan == SubscriptionPlan.family);
  
  int get remainingDays {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }
  
  @override
  List<Object?> get props => [id, plan, status, startDate, endDate];
}

enum SubscriptionPlan {
  free('free', 'Bepul', 0, '🆓'),
  basic('basic', 'Asosiy', 29000, '⭐'),
  premium('premium', 'Premium', 49000, '💎'),
  family('family', 'Oilaviy', 79000, '👨‍👩‍👧‍👦');
  
  final String value;
  final String label;
  final int priceUzs; // In UZS
  final String emoji;
  
  const SubscriptionPlan(this.value, this.label, this.priceUzs, this.emoji);
  
  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionPlan.free,
    );
  }
  
  String get formattedPrice {
    if (priceUzs == 0) return 'Bepul';
    return '${(priceUzs / 1000).toStringAsFixed(0)} 000 so\'m/oy';
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

// Plan features definition
class PlanFeatures {
  static const Map<SubscriptionPlan, List<PlanFeature>> features = {
    SubscriptionPlan.free: [
      PlanFeature(title: 'Reklamali kontent', description: 'Reklamalar bilan', included: true),
      PlanFeature(title: '1 bola profili', description: '', included: true),
      PlanFeature(title: '30 min/kun limit', description: '', included: true),
      PlanFeature(title: 'Premium kontent', description: '', included: false),
      PlanFeature(title: 'AI maslahatlar', description: '', included: false),
    ],
    SubscriptionPlan.basic: [
      PlanFeature(title: 'Reklama yo\'q', description: 'Toza kontentlar', included: true),
      PlanFeature(title: '2 ta bola profili', description: '', included: true),
      PlanFeature(title: '60 min/kun limit', description: '', included: true),
      PlanFeature(title: 'Premium kontent', description: '', included: false),
      PlanFeature(title: 'AI maslahatlar', description: '', included: false),
    ],
    SubscriptionPlan.premium: [
      PlanFeature(title: 'Reklama yo\'q', description: '', included: true),
      PlanFeature(title: '3 ta bola profili', description: '', included: true),
      PlanFeature(title: 'Cheksiz vaqt', description: '', included: true),
      PlanFeature(title: 'Premium kontent', description: 'Maxsus kontentlar', included: true),
      PlanFeature(title: 'AI maslahatlar', description: '', included: true),
    ],
    SubscriptionPlan.family: [
      PlanFeature(title: 'Reklama yo\'q', description: '', included: true),
      PlanFeature(title: '5 ta bola profili', description: '', included: true),
      PlanFeature(title: 'Cheksiz vaqt', description: '', included: true),
      PlanFeature(title: 'Premium kontent', description: '', included: true),
      PlanFeature(title: 'AI maslahatlar', description: 'Personallashtirilgan', included: true),
    ],
  };
}
