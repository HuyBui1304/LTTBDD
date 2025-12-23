import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

class SessionWorkflowScreen extends StatefulWidget {
  final AttendanceSession session;

  const SessionWorkflowScreen({super.key, required this.session});

  @override
  State<SessionWorkflowScreen> createState() => _SessionWorkflowScreenState();
}

class _SessionWorkflowScreenState extends State<SessionWorkflowScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _db.getSessionHistory(widget.session.id!);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(SessionStatus newStatus, String action) async {
    try {
      // Get current user
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập để thực hiện thao tác này')),
          );
        }
        return;
      }

      // Get user ID from database
      final userMaps = await _db.database.then((db) => db.query(
        'users',
        where: 'uid = ?',
        whereArgs: [currentUser.uid],
      ));
      
      if (userMaps.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
          );
        }
        return;
      }
      
      final userId = userMaps.first['id'] as int;

      // Update session status
      final updatedSession = widget.session.copyWith(status: newStatus);
      await _db.updateSession(updatedSession);

      // Log history
      await _db.createSessionHistory({
        'sessionId': widget.session.id,
        'userId': userId,
        'action': action,
        'oldStatus': widget.session.status.name,
        'newStatus': newStatus.name,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _loadHistory();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quy trình xử lý'),
      ),
      body: Column(
        children: [
          // Current Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(status: widget.session.status),
                      const SizedBox(width: 8),
                      Text(
                        widget.session.sessionDate != null
                            ? DateFormat('dd/MM/yyyy HH:mm')
                                .format(widget.session.sessionDate!)
                            : 'Chưa có ngày',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Workflow Actions
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thao tác',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildActionButtons(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // History
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.history,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Lịch sử thao tác',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _history.isEmpty
                            ? const Center(
                                child: Text('Chưa có lịch sử thao tác'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _history.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _history[index];
                                  return _HistoryItem(item: item);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final status = widget.session.status;
    final List<Widget> buttons = [];

    switch (status) {
      case SessionStatus.scheduled:
        buttons.add(
          FilledButton.icon(
            onPressed: () => _updateStatus(SessionStatus.completed, 'complete'),
            icon: const Icon(Icons.done_all),
            label: const Text('Hoàn thành'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        );
        break;

      case SessionStatus.completed:
        // No actions for completed
        break;
    }

    return buttons;
  }
}

class _StatusChip extends StatelessWidget {
  final SessionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case SessionStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case SessionStatus.completed:
        color = Colors.grey;
        icon = Icons.check_circle;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.displayName),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final action = item['action'] as String;
    final createdAt = DateTime.parse(item['createdAt'] as String);
    final userName = item['userName'] as String? ?? 'Unknown';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getActionColor(action).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getActionIcon(action),
          color: _getActionColor(action),
          size: 20,
        ),
      ),
      title: Text(_getActionText(action)),
      subtitle: Text('$userName • ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
      trailing: item['note'] != null
          ? IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Ghi chú'),
                    content: Text(item['note'] as String),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return Colors.green;
      case 'reject':
      case 'cancel':
        return Colors.red;
      case 'complete':
        return Colors.teal;
      case 'start':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'submit_for_approval':
        return Icons.send;
      case 'start':
        return Icons.play_arrow;
      case 'complete':
        return Icons.done_all;
      case 'cancel':
        return Icons.close;
      default:
        return Icons.circle;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'approve':
        return 'Đã phê duyệt';
      case 'reject':
        return 'Đã từ chối';
      case 'submit_for_approval':
        return 'Gửi duyệt';
      case 'start':
        return 'Bắt đầu buổi học';
      case 'complete':
        return 'Hoàn thành';
      case 'cancel':
        return 'Đã hủy';
      case 'created':
        return 'Tạo mới';
      case 'updated':
        return 'Cập nhật';
      default:
        return action;
    }
  }
}

