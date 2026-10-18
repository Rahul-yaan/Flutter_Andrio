import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import 'api_service.dart';

class NotificationService {
  static const String _readIdsKey = 'read_notification_ids';
  static const String _dismissedBannerKey = 'dismissed_banner_id';

  // In-memory cache
  static List<NotificationItem>? _cachedNotifications;

  // Default initial Admin offers & news items for seamless UX
  static List<NotificationItem> _getDefaultAdminBroadcasts() {
    return [
      NotificationItem(
        id: 'offer_spot_welcome',
        title: 'Special Spot Booking Discount 🎉',
        message: 'Admin is offering 20% OFF on all highway hotel spot bookings this month. Use promo code YAANSPOT at checkout!',
        type: 'offer',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        discountCode: 'YAANSPOT',
        discountPercent: 20,
        validTill: 'Limited Period Offer',
      ),
      NotificationItem(
        id: 'news_highway_expansion',
        title: 'Highway Update: 15+ New Partner Dhabas & Hotels',
        message: 'Good news! Yaan has expanded partnerships across NH48 and Mumbai-Delhi expressway. Verified parking, hot meals, and 24x7 security are now available.',
        type: 'news',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      NotificationItem(
        id: 'offer_weekend_stay',
        title: 'Flat ₹200 OFF on Overnight Truck Stops',
        message: 'Get flat ₹200 discount when you book stay for 6+ hours during weekend journeys. Valid at all verified partner hotels.',
        type: 'offer',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        discountCode: 'TRUCK200',
        discountPercent: 15,
        validTill: 'Valid till Sunday',
      ),
      NotificationItem(
        id: 'news_safety_alert',
        title: 'Admin News: Highway Monsoon Safety & Support',
        message: 'Drive safe in rainy conditions. Our 24x7 route roadside assistance helpline is now live directly inside the Profile section.',
        type: 'news',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Fetch notifications (combining API live data with cached/default broadcasts)
  static Future<List<NotificationItem>> getNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedNotifications != null) {
      return _cachedNotifications!;
    }

    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey) ?? [];

    List<NotificationItem> items = [];

    try {
      final res = await ApiService.getNotifications();
      if (res['notifications'] is List && (res['notifications'] as List).isNotEmpty) {
        for (var raw in res['notifications']) {
          if (raw is Map<String, dynamic>) {
            items.add(NotificationItem.fromJson(raw));
          }
        }
      } else if (res['data'] is List && (res['data'] as List).isNotEmpty) {
        for (var raw in res['data']) {
          if (raw is Map<String, dynamic>) {
            items.add(NotificationItem.fromJson(raw));
          }
        }
      }
    } catch (e) {
      debugPrint('Notification fetch from backend failed: $e');
    }

    // Merge default admin offers & news if API provided none
    if (items.isEmpty) {
      items = _getDefaultAdminBroadcasts();
    } else {
      // If API provided some, check if we need to supplement with key offers if missing
      final hasOffers = items.any((n) => n.type == 'offer');
      if (!hasOffers) {
        items.addAll(_getDefaultAdminBroadcasts().where((n) => n.type == 'offer'));
      }
    }

    // Apply read state
    final updated = items.map((item) {
      final isRead = readIds.contains(item.id) || item.isRead;
      return item.copyWith(isRead: isRead);
    }).toList();

    // Sort newest first
    updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _cachedNotifications = updated;
    return updated;
  }

  /// Get count of unread notifications
  static Future<int> getUnreadCount() async {
    final list = await getNotifications();
    return list.where((n) => !n.isRead).length;
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey) ?? [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList(_readIdsKey, readIds);
    }

    if (_cachedNotifications != null) {
      _cachedNotifications = _cachedNotifications!.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final list = await getNotifications();
    final prefs = await SharedPreferences.getInstance();
    final allIds = list.map((e) => e.id).toList();
    await prefs.setStringList(_readIdsKey, allIds);

    if (_cachedNotifications != null) {
      _cachedNotifications = _cachedNotifications!.map((item) {
        return item.copyWith(isRead: true);
      }).toList();
    }
  }

  /// Get the latest offer or news banner to show on the Home Page notification bar
  static Future<NotificationItem?> getLatestBannerNotification() async {
    final list = await getNotifications();
    if (list.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final dismissedId = prefs.getString(_dismissedBannerKey);

    // Prefer first unread offer or news
    final unreadItem = list.firstWhere(
      (n) => !n.isRead && n.id != dismissedId,
      orElse: () => list.firstWhere(
        (n) => n.id != dismissedId,
        orElse: () => list.first,
      ),
    );

    if (unreadItem.id == dismissedId) return null;
    return unreadItem;
  }

  /// Dismiss the home page banner notification
  static Future<void> dismissBanner(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedBannerKey, id);
  }
}
