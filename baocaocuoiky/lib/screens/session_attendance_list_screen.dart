import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import 'qr_display_screen.dart';
import 'manual_attendance_screen.dart';

class SessionAttendanceListScreen extends StatefulWidget {
  final AttendanceSession session;

  const SessionAttendanceListScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionAttendanceListScreen> createState() => _SessionAttendanceListScreenState();
}

class _SessionAttendanceListScreenState extends State<SessionAttendanceListScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Student> _allStudents = [];
  Map<int, AttendanceRecord> _recordsMap = {}; // studentId -> record
  bool _isLoading = true;
  int _presentCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _db.getRecordsBySession(widget.session.id!);
      final students = await _db.getStudentsByClass(widget.session.classCode);

      final recordsMap = <int, AttendanceRecord>{};
      for (var record in records) {
        recordsMap[record.studentId] = record;
      }

      setState(() {
        _allStudents = students;
        _recordsMap = recordsMap;
        _presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
        _totalCount = students.length;
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
        title: Text(widget.session.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons (only show if session not completed)
          if (widget.session.status != SessionStatus.completed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRDisplayScreen(session: widget.session),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Tạo mã QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManualAttendanceScreen(session: widget.session),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Điểm danh thủ công'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Statistics card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$_totalCount',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Text('Tổng số'),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Column(
                  children: [
                    Text(
                      '$_presentCount',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    const Text('Đã điểm danh'),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Column(
                  children: [
                    Text(
                      '${_totalCount - _presentCount}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                    ),
                    const Text('Chưa điểm danh'),
                  ],
                ),
              ],
            ),
          ),

          // Students list
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách học sinh...')
                : _allStudents.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.people_outline,
                        title: 'Chưa có học sinh nào',
                        message: 'Lớp này chưa có học sinh',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _allStudents.length,
                          itemBuilder: (context, index) {
                            final student = _allStudents[index];
                            final record = _recordsMap[student.id];
                            final hasAttended = record != null;
                            final status = record?.status ?? AttendanceStatus.absent;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasAttended
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  child: Icon(
                                    hasAttended ? Icons.check_circle : Icons.cancel,
                                    color: hasAttended ? Colors.green : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Mã SV: ${student.studentId}'),
                                    if (hasAttended) ...[
                                      Text(
                                        'Điểm danh: ${DateFormat('dd/MM/yyyy HH:mm').format(record.checkInTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Phương thức: ${record.checkInMethod.displayName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    hasAttended ? 'Đã điểm danh' : 'Chưa điểm danh',
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }
}
