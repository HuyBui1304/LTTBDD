import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import '../services/export_service.dart';
import 'session_attendance_list_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ExportService _exportService = ExportService.instance;
  List<AttendanceSession> _sessions = [];
  AppUser? _teacher;
  bool _isLoading = true;
  bool _isExporting = false;

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
      // Ignore error
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      if (widget.subject.id != null) {
        final sessions = await _db.getSessionsBySubject(widget.subject.id!);
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  // Lấy số lượng học sinh đã điểm danh
  Future<int> _getAttendanceCount(int sessionId) async {
    final records = await _db.getRecordsBySession(sessionId);
    return records.length;
  }

  // Lấy record điểm danh của học sinh cho buổi học
  Future<AttendanceRecord?> _getStudentRecord(int sessionId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser == null) return null;

      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
      );

      if (student.id == null) return null;

      return await _db.getRecordBySessionAndStudent(sessionId, student.id!);
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportToCSV() async {
    if (_sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Môn học này chưa có buổi học nào')),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      await _exportService.exportAndShareSessionsCSV(
        subject: widget.subject,
        sessions: _sessions,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất CSV thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPDF() async {
    if (_sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Môn học này chưa có buổi học nào')),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      await _exportService.exportAndShareSessionsPDF(
        subject: widget.subject,
        sessions: _sessions,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất PDF thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // Hiển thị dialog chi tiết buổi học cho học sinh
  void _showSessionDetailDialog(AttendanceSession session, AttendanceRecord? record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.sessionDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (session.location != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 8),
                    Text('Địa điểm: ${session.location}'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    record != null ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: record != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record != null ? 'Đã điểm danh' : 'Chưa điểm danh',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: record != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (record != null) ...[
                const SizedBox(height: 8),
                Text('Trạng thái: ${record.status.displayName}'),
                const SizedBox(height: 4),
                Text(
                  'Thời gian điểm danh: ${DateFormat('dd/MM/yyyy HH:mm').format(record.checkInTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTeacher = authProvider.isTeacher || authProvider.isAdmin;
    final isStudent = authProvider.isStudent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
        actions: [
          if (isTeacher) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'export_csv') {
                  _exportToCSV();
                } else if (value == 'export_pdf') {
                  _exportToPDF();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export_csv',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 20),
                      SizedBox(width: 8),
                      Text('Xuất CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 20),
                      SizedBox(width: 8),
                      Text('Xuất PDF'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xuất file...'),
                ],
              ),
            )
          : Column(
        children: [
          // Subject info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.subjectName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Mã môn: ${widget.subject.subjectCode}'),
                Text('Lớp: ${widget.subject.classCode}'),
                if (_teacher != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text('Giảng viên: ${_teacher!.displayName}'),
                    ],
                  ),
                ],
                if (widget.subject.description != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.subject.description!),
                ],
              ],
            ),
          ),

          // Sessions list
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách buổi học...')
                : _sessions.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.event_outlined,
                        title: 'Chưa có buổi học nào',
                        message: 'Môn học này chưa có buổi học',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            return _SessionCard(
                              session: session,
                              isTeacher: isTeacher,
                              isStudent: isStudent,
                              onTap: () async {
                                if (isTeacher) {
                                  // Giáo viên: Hiển thị danh sách học sinh
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SessionAttendanceListScreen(session: session),
                                    ),
                                  ).then((_) => _loadSessions());
                                } else if (isStudent) {
                                  // Học sinh: Xem chi tiết buổi học và trạng thái điểm danh
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final currentUser = authProvider.currentUser;
                                  if (currentUser != null) {
                                    final allStudents = await _db.getAllStudents();
                                    final student = allStudents.firstWhere(
                                      (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
                                      orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
                                    );
                                    
                                    if (student.id != null && session.id != null) {
                                      final record = await _db.getRecordBySessionAndStudent(
                                        session.id!,
                                        student.id!,
                                      );
                                      
                                      if (mounted) {
                                        _showSessionDetailDialog(session, record);
                                      }
                                    }
                                  }
                                }
                              },
                              getAttendanceCount: _getAttendanceCount,
                              getStudentRecord: isStudent ? _getStudentRecord : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

}

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final bool isTeacher;
  final bool isStudent;
  final VoidCallback onTap;
  final Future<int> Function(int) getAttendanceCount;
  final Future<AttendanceRecord?> Function(int)? getStudentRecord;

  const _SessionCard({
    required this.session,
    required this.isTeacher,
    required this.isStudent,
    required this.onTap,
    required this.getAttendanceCount,
    this.getStudentRecord,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasRecords(),
      builder: (context, snapshot) {
        final hasRecords = snapshot.data ?? false;
        
        return FutureBuilder<int>(
          future: hasRecords ? getAttendanceCount(session.id!) : Future.value(0),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                onTap: onTap,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 4),
                    Text('${_getStatusText(session.status)}'),
                    if (session.sessionDate != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!),
                      ),
                    if (session.location != null) Text('Địa điểm: ${session.location}'),
                    if (isTeacher && hasRecords) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đã điểm danh: $count học sinh',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: isStudent && getStudentRecord != null
                    ? FutureBuilder<AttendanceRecord?>(
                        future: getStudentRecord!(session.id!),
                        builder: (context, snapshot) {
                          final record = snapshot.data;
                          if (record != null) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  record.status.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Icon(
                              Icons.cancel,
                              color: Colors.grey,
                            );
                          }
                        },
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isTeacher)
                            hasRecords
                                ? Icon(
                                    Icons.people,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : Icon(
                                    Icons.qr_code,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _hasRecords() async {
    final db = DatabaseHelper.instance;
    final records = await db.getRecordsBySession(session.id!);
    return records.isNotEmpty;
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return Colors.grey;
      case SessionStatus.scheduled:
        return Colors.blue;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Đã hoàn thành';
      case SessionStatus.scheduled:
        return 'Chưa diễn ra';
    }
  }
}
