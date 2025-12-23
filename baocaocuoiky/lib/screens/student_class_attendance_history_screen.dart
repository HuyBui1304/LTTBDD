import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;

class StudentClassAttendanceHistoryScreen extends StatefulWidget {
  final String classCode;

  const StudentClassAttendanceHistoryScreen({
    super.key,
    required this.classCode,
  });

  @override
  State<StudentClassAttendanceHistoryScreen> createState() =>
      _StudentClassAttendanceHistoryScreenState();
}

class _StudentClassAttendanceHistoryScreenState
    extends State<StudentClassAttendanceHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<AttendanceSession> _sessions = [];
  Map<int, AttendanceRecord> _records = {}; // sessionId -> record
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) return;

      // Get student info
      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
      );

      if (student.id == null) {
        throw Exception('Thông tin học sinh không hợp lệ');
      }

      // Get all sessions for this class
      final sessions = await _db.getAllSessions(classCode: widget.classCode);

      // Get attendance records for this student
      final records = <int, AttendanceRecord>{};
      for (final session in sessions) {
        if (session.id != null) {
          final record = await _db.getRecordBySessionAndStudent(
            session.id!,
            student.id!,
          );
          if (record != null) {
            records[session.id!] = record;
          }
        }
      }

      setState(() {
        _sessions = sessions;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lớp ${widget.classCode}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải...')
          : _sessions.isEmpty
              ? const custom.EmptyWidget(
                  icon: Icons.event_busy,
                  title: 'Chưa có buổi học nào',
                  message: 'Lớp này chưa có buổi học',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final record = _records[session.id];
                      final hasAttended = record != null;
                      final isCompleted = session.status == SessionStatus.completed;

                      // Chỉ hiển thị "đã điểm danh" hoặc "vắng" nếu buổi học đã hoàn thành
                      // Nếu chưa diễn ra thì hiển thị "Chưa diễn ra"
                      String statusText;
                      Color statusColor;
                      IconData statusIcon;
                      
                      if (!isCompleted) {
                        statusText = 'Chưa diễn ra';
                        statusColor = Colors.grey;
                        statusIcon = Icons.schedule;
                      } else if (hasAttended) {
                        statusText = 'Đã điểm danh';
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      } else {
                        statusText = 'Vắng';
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            session.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                session.sessionDate != null
                                    ? DateFormat('dd/MM/yyyy HH:mm')
                                        .format(session.sessionDate!)
                                    : 'Chưa có ngày',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (isCompleted && hasAttended)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Đã điểm danh - ${DateFormat('dd/MM/yyyy HH:mm').format(record.checkInTime)}',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              else if (!isCompleted)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Chưa diễn ra',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

