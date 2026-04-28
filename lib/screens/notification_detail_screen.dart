import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' show AppNotification;
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _getTargetText(AppNotification notification) {
    if (notification.targetUserId != null) {
      return 'Gửi đến người dùng cụ thể';
    } else if (notification.targetClassCode != null) {
      return 'Lớp: ${notification.targetClassCode}';
    } else if (notification.targetRole != null) {
      switch (notification.targetRole) {
        case 'admin':
          return 'Tất cả quản trị viên';
        case 'teacher':
          return 'Tất cả giáo viên';
        case 'student':
          return 'Tất cả học sinh';
        default:
          return 'Tất cả người dùng';
      }
    } else {
      return 'Tất cả người dùng';
    }
  }

  Future<void> _markAsRead(BuildContext context, AppNotification notification) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null || notification.id == null) return;

    try {
      await DatabaseHelper.instance.markNotificationAsRead(notification.id!, currentUser.uid);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
        );
      }
    }
  }

  bool _isRead(BuildContext context, AppNotification notification) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return false;
    return notification.readBy != null && notification.readBy!.contains(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final isRead = _isRead(context, notification);
    
    // Mark as read when viewing details
    if (!isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markAsRead(context, notification);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRead 
                        ? Colors.grey.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRead ? Icons.check_circle : Icons.notifications,
                        size: 16,
                        color: isRead ? Colors.grey : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRead ? 'Đã đọc' : 'Chưa đọc',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRead ? Colors.grey : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              notification.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            
            // Information section
            Text(
              'Thông tin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Target
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Gửi đến',
              value: _getTargetText(notification),
            ),
            const SizedBox(height: 12),
            
            // Created date
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              label: 'Thời gian',
              value: DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(notification.createdAt),
            ),
            const SizedBox(height: 12),
            
            // Created by
            FutureBuilder<String>(
              future: _getCreatorName(context, notification.createdBy),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                return _buildInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Người tạo',
                  value: snapshot.data ?? 'Không xác định',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> _getCreatorName(BuildContext context, String creatorUid) async {
    try {
      final user = await DatabaseHelper.instance.getUserByUid(creatorUid);
      return user?.displayName ?? 'Không xác định';
    } catch (e) {
      return 'Không xác định';
    }
  }
}

