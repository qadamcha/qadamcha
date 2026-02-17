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

  bool get isPremium => isActive;

  int get remainingDays {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  @override
  List<Object?> get props => [id, plan, status, startDate, endDate];
}

enum SubscriptionPlan {
  monthly('monthly', 'Oylik', 100000, '⭐');

  final String value;
  final String label;
  final int priceUzs;
  final String emoji;

  const SubscriptionPlan(this.value, this.label, this.priceUzs, this.emoji);

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.monthly;
  }

  String get formattedPrice {
    final thousands = (priceUzs / 1000).toStringAsFixed(0);
    return '$thousands 000 so\'m/oy';
  }

  String get periodLabel {
     return '30 kun';
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
  };
}

// ============= Subscribe API Entity Classes =============

/// Karta token ma'lumotlari
class CardToken extends Equatable {
  final String token;
  final String maskedNumber; // 860006******6311
  final String expire;
  final String type; // uzcard, humo
  final bool recurrent;

  const CardToken({
    required this.token,
    required this.maskedNumber,
    required this.expire,
    required this.type,
    this.recurrent = false,
  });

  factory CardToken.fromJson(Map<String, dynamic> json) {
    return CardToken(
      token: json['token'] ?? '',
      maskedNumber: json['number'] ?? json['maskedNumber'] ?? '',
      expire: json['expire'] ?? '',
      type: json['type'] ?? 'unknown',
      recurrent: json['recurrent'] ?? false,
    );
  }

  @override
  List<Object?> get props => [token, maskedNumber];
}

/// SMS tasdiqlash kodi natijasi
class VerifyCodeResult extends Equatable {
  final bool sent;
  final String phone; // Maskirovka qilingan: 99890*****12
  final int wait; // Qayta yuborish vaqti (soniya)

  const VerifyCodeResult({
    required this.sent,
    required this.phone,
    required this.wait,
  });

  factory VerifyCodeResult.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResult(
      sent: json['sent'] ?? false,
      phone: json['phone'] ?? '',
      wait: json['wait'] ?? 60,
    );
  }

  @override
  List<Object?> get props => [sent, phone, wait];
}

/// To'lov natijasi
class PaymentResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? receiptId;
  final int? state;
  final String? message;
  final Subscription? subscription;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.receiptId,
    this.state,
    this.message,
    this.subscription,
  });

  @override
  List<Object?> get props => [success, transactionId, receiptId, state];
}
