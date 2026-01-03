import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' show AppNotification;
import '../models/app_user.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart' show UserRole;
import 'notification_detail_screen.dart';
import 'create_notification_screen.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Lấy classCodes của user
      List<String>? userClassCodes;
      
      if (currentUser.role == UserRole.student) {
        // Student: Lấy classCodes từ subjects mà student học
        final allStudents = await _db.getAllStudents();
        final student = allStudents.firstWhere(
          (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
          orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
        );
        
        if (student.subjectIds != null && student.subjectIds!.isNotEmpty) {
          final allSubjects = await _db.getAllSubjects();
          userClassCodes = allSubjects
              .where((s) => student.subjectIds!.contains(s.id.toString()))
              .map((s) => s.classCode)
              .toList();
        }
      } else if (currentUser.role == UserRole.teacher) {
        // Teacher: Lấy classCodes từ subjects mà teacher dạy
        final subjects = await _db.getSubjectsByCreator(currentUser.uid);
        userClassCodes = subjects.map((s) => s.classCode).toList();
      }
      
      final notifications = await _db.getNotificationsForUser(
        userId: currentUser.uid,
        userRole: currentUser.role.name,
        userClassCodes: userClassCodes,
      );
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông báo: $e')),
        );
      }
    }
  }

  bool _isRead(AppNotification notification) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return false;
    return notification.readBy != null && notification.readBy!.contains(currentUser.uid);
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    if (notification.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteNotification(notification.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thông báo')),
          );
          _loadNotifications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa thông báo: $e')),
          );
        }
      }
    }
  }

  String _getTargetText(AppNotification notification) {
    if (notification.targetUserId != null) {
      return 'Gửi đến bạn';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final canCreateNotification = currentUser?.role == UserRole.teacher || 
                                     currentUser?.role == UserRole.admin;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông báo'),
            actions: canCreateNotification
                ? [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateNotificationScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadNotifications();
                        }
                      },
                      tooltip: 'Tạo thông báo mới',
                    ),
                  ]
                : null,
          ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thông báo nào',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (canCreateNotification) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateNotificationScreen(),
                              ),
                            );
                            if (result == true && mounted) {
                              _loadNotifications();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo thông báo đầu tiên'),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = _isRead(notification);
                      
                      final canDelete = currentUser?.uid == notification.createdBy;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        color: isRead 
                            ? null 
                            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        child: InkWell(
                          onTap: () {
                            // Navigate to detail screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationDetailScreen(
                                  notification: notification,
                                ),
                              ),
                            ).then((_) {
                              // Reload notifications after returning
                              _loadNotifications();
                            });
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isRead 
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: isRead ? Colors.grey : Colors.red,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(notification.content),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTargetText(notification),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(notification.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: canDelete
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteNotification(notification),
                                    tooltip: 'Xóa thông báo',
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

