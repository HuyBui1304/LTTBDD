import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/attendance_session.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import 'qr_scanner_screen.dart';
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
  List<AttendanceSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
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
  

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTeacher = authProvider.isTeacher || authProvider.isAdmin;
    final isStudent = authProvider.isStudent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
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
                                  // Học sinh: Quét QR để điểm danh
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QRScannerScreen(session: session),
                                    ),
                                  );
                                }
                              },
                              getAttendanceCount: _getAttendanceCount,
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

  const _SessionCard({
    required this.session,
    required this.isTeacher,
    required this.isStudent,
    required this.onTap,
    required this.getAttendanceCount,
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
                trailing: Column(
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
                    if (isStudent)
                      hasRecords
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : Icon(
                              Icons.cancel,
                              color: Colors.grey,
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
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Đã hoàn thành';
      case SessionStatus.scheduled:
        return 'Chưa diễn ra';
      default:
        return status.displayName;
    }
  }
}
