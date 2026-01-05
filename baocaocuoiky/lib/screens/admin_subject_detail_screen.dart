import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/attendance_session.dart';
import '../models/app_user.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import 'session_detail_screen.dart';
import 'edit_subject_screen.dart';

class AdminSubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const AdminSubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  State<AdminSubjectDetailScreen> createState() => _AdminSubjectDetailScreenState();
}

class _AdminSubjectDetailScreenState extends State<AdminSubjectDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<AttendanceSession> _sessions = [];
  AppUser? _teacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSessions(),
      _loadTeacher(),
    ]);
  }

  Future<void> _loadTeacher() async {
    try {
      if (widget.subject.creatorId != null && widget.subject.creatorId!.isNotEmpty) {
        // Lấy thông tin giáo viên từ UID
        final teacher = await _db.getUserByUid(widget.subject.creatorId!);
        if (mounted) {
          setState(() {
            _teacher = teacher;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin giáo viên: $e');
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      if (widget.subject.id != null) {
        debugPrint('🔍 Loading sessions for subject ID: ${widget.subject.id}');
        final sessions = await _db.getSessionsBySubject(widget.subject.id!);
        debugPrint('📋 Found ${sessions.length} sessions for subject ${widget.subject.subjectCode}');
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      } else {
        debugPrint('⚠️ Subject ID is null, cannot load sessions');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa môn học "${widget.subject.subjectName}"?\n\nLưu ý: Tất cả buổi học và dữ liệu điểm danh liên quan sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (widget.subject.id != null) {
        await _db.deleteSubject(widget.subject.id!);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, true); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa môn học thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa môn học: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Môn học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSubjectScreen(subject: widget.subject),
                ),
              );
              if (result == true && mounted) {
                _loadData();
              }
            },
            tooltip: 'Chỉnh sửa',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSubject,
            tooltip: 'Xóa môn học',
            color: Colors.red,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin môn học',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.book, 'Tên môn học', widget.subject.subjectName),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.code, 'Mã môn học', widget.subject.subjectCode),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.class_, 'Mã lớp', widget.subject.classCode),
                    if (_teacher != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(context, Icons.person, 'Giáo viên', _teacher!.displayName),
                    ],
                    if (widget.subject.description != null && widget.subject.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(context, Icons.description, 'Mô tả', widget.subject.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách buổi học (${_sessions.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const custom.LoadingWidget(message: 'Đang tải buổi học...')
                        : _sessions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Chưa có buổi học nào'),
                              )
                            : Column(
                                children: _sessions.map((session) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(session.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.event,
                                        color: _getStatusColor(session.status),
                                      ),
                                    ),
                                    title: Text(
                                      session.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Mã buổi: ${session.sessionCode}'),
                                        Text('Buổi số: ${session.sessionNumber}'),
                                        if (session.sessionDate != null)
                                          Text('Ngày: ${session.sessionDate!.day}/${session.sessionDate!.month}/${session.sessionDate!.year}'),
                                      ],
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        session.status.name == 'scheduled' ? 'Chưa diễn ra' : 'Đã hoàn thành',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: _getStatusColor(session.status).withOpacity(0.1),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SessionDetailScreen(session: session),
                                        ),
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                );
                                }).toList(),
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.green;
    }
  }
}

