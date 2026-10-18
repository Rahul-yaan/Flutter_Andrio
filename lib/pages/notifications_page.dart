import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // 'all', 'offer', 'news'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final items = await NotificationService.getNotifications(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _notifications = items;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onNotificationTap(NotificationItem item) async {
    if (!item.isRead) {
      await NotificationService.markAsRead(item.id);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n.id == item.id) return n.copyWith(isRead: true);
            return n;
          }).toList();
        });
      }
    }

    if (!mounted) return;

    // Show details modal if clicked
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationDetailSheet(
        item: item,
        onCopyCode: (code) => _copyPromoCode(code),
      ),
    );
  }

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF27AE60),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Coupon code "$code" copied!'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'all') return true;
      return n.type == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        elevation: 0,
        title: const Text(
          'Notifications & Offers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text(
                'Mark read',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Icons.all_inbox_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Offers & Deals', 'offer', Icons.local_offer_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('News & Alerts', 'news', Icons.campaign_rounded),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFC0392B),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFC0392B),
                    onRefresh: () => _loadNotifications(forceRefresh: true),
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final item = filtered[index];
                              return _buildNotificationCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, IconData icon) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC0392B) : const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC0392B).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF444444),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isOffer = item.type == 'offer';

    return GestureDetector(
      onTap: () => _onNotificationTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFDFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFEEEEEE)
                : const Color(0xFFC0392B).withValues(alpha: 0.25),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Pill & Time & Unread Dot
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOffer
                        ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                        : const Color(0xFF2980B9).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffer ? Icons.local_offer : Icons.campaign_rounded,
                        size: 12,
                        color: isOffer ? const Color(0xFF27AE60) : const Color(0xFF2980B9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOffer ? 'ADMIN OFFER' : 'ADMIN NEWS',
                        style: TextStyle(
                          color: isOffer ? const Color(0xFF27AE60) : const Color(0xFF2980B9),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.discountPercent != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.discountPercent}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                ),
                if (!item.isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC0392B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 6),

            // Message
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Coupon Code box if applicable
            if (item.discountCode != null && item.discountCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFDDDDDD),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 16, color: Color(0xFFC0392B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROMO CODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF888888),
                            ),
                          ),
                          Text(
                            item.discountCode!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Color(0xFFC0392B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyPromoCode(item.discountCode!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: Color(0xFFC0392B)),
                            SizedBox(width: 4),
                            Text(
                              'COPY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC0392B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (item.validTill != null && item.validTill!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF888888)),
                  const SizedBox(width: 4),
                  Text(
                    item.validTill!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 54,
                color: Color(0xFFC0392B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When the admin broadcasts new offers, discount vouchers, or highway news updates, they will appear right here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF777777),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;
  final Function(String) onCopyCode;

  const _NotificationDetailSheet({
    required this.item,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final isOffer = item.type == 'offer';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffer
                      ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                      : const Color(0xFF2980B9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOffer ? 'SPECIAL OFFER' : 'ADMIN NEWS & ALERT',
                  style: TextStyle(
                    color: isOffer ? const Color(0xFF27AE60) : const Color(0xFF2980B9),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            item.message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),

          if (item.discountCode != null && item.discountCode!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COUPON CODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.discountCode!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFFC0392B),
                          ),
                        ),
                        if (item.validTill != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.validTill!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      onCopyCode(item.discountCode!);
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Primary action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close sheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isOffer ? 'Explore Hotels Now' : 'Got it',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
