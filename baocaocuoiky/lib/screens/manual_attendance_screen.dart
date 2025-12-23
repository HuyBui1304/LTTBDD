import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;

class ManualAttendanceScreen extends StatefulWidget {
  final AttendanceSession session;

  const ManualAttendanceScreen({
    super.key,
    required this.session,
  });

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Student> _allStudents = [];
  Map<int, AttendanceRecord> _recordsMap = {}; // studentId -> record
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _db.getStudentsByClass(widget.session.classCode);
      final records = await _db.getRecordsBySession(widget.session.id!);

      final recordsMap = <int, AttendanceRecord>{};
      for (var record in records) {
        recordsMap[record.studentId] = record;
      }

      setState(() {
        _allStudents = students;
        _recordsMap = recordsMap;
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

  Future<int> _getTeacherId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) throw Exception('Chưa đăng nhập');
    
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [currentUser.uid],
    );
    if (maps.isEmpty) throw Exception('Không tìm thấy thông tin người dùng');
    return maps.first['id'] as int;
  }

  Future<void> _markAttendance(Student student, AttendanceStatus status) async {
    try {
      final teacherId = await _getTeacherId();
      final existing = _recordsMap[student.id];
      
      final record = AttendanceRecord(
        id: existing?.id,
        sessionId: widget.session.id!,
        studentId: student.id!,
        status: status,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.manual,
        checkedByTeacherId: teacherId,
        note: 'Giáo viên điểm danh thủ công',
      );

      if (existing != null) {
        await _db.updateRecord(record);
      } else {
        await _db.createRecord(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã điểm danh: ${student.name}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttendanceDialog(Student student) {
    final existing = _recordsMap[student.id];
    AttendanceStatus selectedStatus = existing?.status ?? AttendanceStatus.present;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Điểm danh - ${student.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mã SV: ${student.studentId}'),
              const SizedBox(height: 16),
              ...AttendanceStatus.values.map((status) => RadioListTile<AttendanceStatus>(
                    title: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(status.displayName),
                      ],
                    ),
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setDialogState(() => selectedStatus = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _markAttendance(student, selectedStatus);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.info;
    }
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

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudents;
    final query = _searchQuery.toLowerCase();
    return _allStudents.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh thủ công - ${widget.session.title}'),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm học sinh...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),

          // Students list
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách học sinh...')
                : _filteredStudents.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.people_outline,
                        title: _searchQuery.isNotEmpty
                            ? 'Không tìm thấy học sinh'
                            : 'Chưa có học sinh nào',
                        message: _searchQuery.isNotEmpty
                            ? 'Thử tìm kiếm với từ khóa khác'
                            : 'Lớp này chưa có học sinh',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final record = _recordsMap[student.id];
                            final hasAttended = record != null;
                            final status = record?.status ?? AttendanceStatus.absent;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        'Trạng thái: ${status.displayName}',
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Phương thức: ${record.checkInMethod.displayName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ] else
                                      const Text(
                                        'Chưa điểm danh',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    hasAttended ? Icons.edit : Icons.check_circle,
                                    color: hasAttended 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.green,
                                  ),
                                  onPressed: () => _showAttendanceDialog(student),
                                  tooltip: hasAttended ? 'Sửa điểm danh' : 'Điểm danh',
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
}
