import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import 'api_service.dart';

class NotificationService {
  static const String _readIdsKey = 'read_notification_ids';
  static const String _dismissedBannerKey = 'dismissed_banner_id';

  // In-memory cache
  static List<NotificationItem>? _cachedNotifications;

  /// Fetch notifications uploaded by admin (from /notifications and /banners API)
  static Future<List<NotificationItem>> getNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedNotifications != null) {
      return _cachedNotifications!;
    }

    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey) ?? [];

    List<NotificationItem> items = [];

    // 1. Fetch from notifications API
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

    // 2. Supplement with active promotional banners/ads uploaded by admin
    try {
      final banners = await ApiService.getBanners(target: 'user');
      for (var raw in banners) {
        final id = raw['id']?.toString() ?? '';
        if (!items.any((existing) => existing.id == id)) {
          items.add(NotificationItem.fromJson(raw));
        }
      }
    } catch (e) {
      debugPrint('Banner fetch for notifications failed: $e');
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