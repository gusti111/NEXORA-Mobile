import 'package:flutter/material.dart';

import '../services/api_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.getNotifications();
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _error = result['message']?.toString() ??
            'Notifikasi tidak dapat dimuat.';
        _loading = false;
      });
      return;
    }

    final data = result['data'] as List? ?? [];
    setState(() {
      _notifications = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      _unreadCount = (result['unread_count'] as int?) ?? 0;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final result = await ApiService.markAllNotificationsRead();
    if (!mounted) return;
    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memperbarui notifikasi.')),
      );
      return;
    }
    await _load();
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['read_at'] != null) return;
    final id = item['id']?.toString();
    if (id == null) return;

    final result = await ApiService.markNotificationRead(id);
    if (!mounted) return;
    if (result['success'] == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menandai notifikasi.')),
      );
    }
  }

  String _dateLabel(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return '';
    return parsed.day.toString().padLeft(2, '0') +
        '/' +
        parsed.month.toString().padLeft(2, '0') +
        '/' +
        parsed.year.toString() +
        ' ' +
        parsed.hour.toString().padLeft(2, '0') +
        ':' +
        parsed.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF145C4B),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.cloud_off, size: 42, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton(
                          onPressed: _load,
                          child: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  )
                : _notifications.isEmpty
                    ? const ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 130),
                          Icon(Icons.notifications_none,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada notifikasi',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final data = item['data'] is Map
                              ? Map<String, dynamic>.from(item['data'])
                              : <String, dynamic>{};
                          final isUnread = item['read_at'] == null;
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _markRead(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      data['event'] == 'logbook_reviewed'
                                          ? Icons.fact_check_outlined
                                          : Icons.menu_book_outlined,
                                      color: const Color(0xFF145C4B),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title']?.toString() ??
                                                'Notifikasi NEXORA',
                                            style: TextStyle(
                                              fontWeight: isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            data['message']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                          if (data['comment'] != null &&
                                              data['comment']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Catatan: ' +
                                                  data['comment'].toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(
                                            _dateLabel(item['created_at']),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isUnread)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 5),
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Color(0xFF176B4D),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
