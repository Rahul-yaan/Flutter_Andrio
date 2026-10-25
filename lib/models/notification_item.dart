class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'offer', 'news', 'system'
  final DateTime createdAt;
  final String? discountCode;
  final int? discountPercent;
  final String? validTill;
  final String? bannerUrl;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.discountCode,
    this.discountPercent,
    this.validTill,
    this.bannerUrl,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['date'] != null
              ? DateTime.parse(json['date'].toString())
              : DateTime.now());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final code = json['discount_code']?.toString() ?? json['promo_code']?.toString();
    final discRaw = json['discount_percentage'] ?? json['discount_percent'];
    int? discVal;
    if (discRaw != null) {
      discVal = num.tryParse(discRaw.toString())?.round();
    }

    String determinedType = 'news';
    if (json['type'] != null && json['type'].toString().trim().isNotEmpty) {
      determinedType = json['type'].toString().toLowerCase();
    } else if ((code != null && code.isNotEmpty) || (discVal != null && discVal > 0)) {
      determinedType = 'offer';
    }

    return NotificationItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      type: determinedType,
      createdAt: parsedDate,
      discountCode: code,
      discountPercent: discVal,
      validTill: json['valid_till']?.toString() ?? json['expires_at']?.toString(),
      bannerUrl: json['banner_url']?.toString() ?? json['image_url']?.toString(),
      isRead: json['is_read'] == true || json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'discount_code': discountCode,
      'discount_percent': discountPercent,
      'valid_till': validTill,
      'banner_url': bannerUrl,
      'is_read': isRead,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    String? discountCode,
    int? discountPercent,
    String? validTill,
    String? bannerUrl,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      discountCode: discountCode ?? this.discountCode,
      discountPercent: discountPercent ?? this.discountPercent,
      validTill: validTill ?? this.validTill,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}