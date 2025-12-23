import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import 'qr_display_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/export_service.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class SessionDetailScreen extends StatefulWidget {
  final AttendanceSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  List<AttendanceRecord> _records = [];
  List<Student> _students = [];
  Map<String, int>? _stats;

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
      final stats = await _db.getSessionStats(widget.session.id!);

      setState(() {
        _records = records;
        _students = students;
        _stats = stats;
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

  void _showAttendanceDialog(Student student) {
    // Check if student already has attendance record
    final existingRecord = _records.firstWhere(
      (r) => r.studentId == student.id,
      orElse: () => AttendanceRecord(
        sessionId: widget.session.id!,
        studentId: student.id!,
      ),
    );

    AttendanceStatus selectedStatus = existingRecord.status;
    final noteController = TextEditingController(text: existingRecord.note);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Điểm danh - ${student.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final record = AttendanceRecord(
                    id: existingRecord.id,
                    sessionId: widget.session.id!,
                    studentId: student.id!,
                    status: selectedStatus,
                    checkInTime: DateTime.now(),
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );

                  if (existingRecord.id != null) {
                    await _db.updateRecord(record);
                  } else {
                    await _db.createRecord(record);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Điểm danh thành công')),
                    );
                  }
                  _loadData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAttendanceAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điểm danh nhanh'),
        content: const Text('Đánh dấu tất cả sinh viên là "Có mặt"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                for (final student in _students) {
                  // Check if record exists
                  final existing = _records.firstWhere(
                    (r) => r.studentId == student.id,
                    orElse: () => AttendanceRecord(
                      sessionId: widget.session.id!,
                      studentId: student.id!,
                    ),
                  );

                  if (existing.id == null) {
                    await _db.createRecord(AttendanceRecord(
                      sessionId: widget.session.id!,
                      studentId: student.id!,
                      status: AttendanceStatus.present,
                      checkInTime: DateTime.now(),
                    ));
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Điểm danh nhanh thành công')),
                  );
                }
                _loadData();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isStudent = authProvider.isStudent;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết buổi học'),
            actions: isStudent
                ? [
                    // Student: Chỉ có quét QR
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRScannerScreen(session: widget.session),
                          ),
                        ).then((_) => _loadData());
                      },
                      tooltip: 'Quét mã QR',
                    ),
                  ]
                : [
                    // Admin/Teacher: Đầy đủ tính năng
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRDisplayScreen(session: widget.session),
                          ),
                        );
                      },
                      tooltip: 'Hiển thị mã QR',
                    ),
                    IconButton(
                      icon: const Icon(Icons.speed),
                      onPressed: _showQuickAttendanceAll,
                      tooltip: 'Điểm danh nhanh',
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export_csv',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart),
                              SizedBox(width: 12),
                              Text('Xuất CSV'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf),
                              SizedBox(width: 12),
                              Text('Xuất PDF'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'export_csv') {
                          _exportCSV();
                        } else if (value == 'export_pdf') {
                          _exportPDF();
                        }
                      },
                    ),
                  ],
          ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải dữ liệu...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Info Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getSessionStatusColor(widget.session.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event,
                                  color: _getSessionStatusColor(widget.session.status),
                                  size: 32,
                                ),
                              ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.session.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                        Chip(
                                          label: Text(
                                            widget.session.status.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getSessionStatusColor(
                                                  widget.session.status),
                                            ),
                                          ),
                                          backgroundColor: _getSessionStatusColor(
                                                  widget.session.status)
                                              .withOpacity(0.1),
                                          side: BorderSide.none,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.qr_code,
                              label: 'Mã buổi học',
                              value: widget.session.sessionCode,
                            ),
                            _InfoRow(
                              icon: Icons.class_,
                              label: 'Mã lớp',
                              value: widget.session.classCode,
                            ),
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Ngày giờ',
                              value: widget.session.sessionDate != null
                                  ? DateFormat('EEEE, dd/MM/yyyy HH:mm', 'vi_VN')
                                      .format(widget.session.sessionDate!)
                                  : 'Chưa có ngày',
                            ),
                            if (widget.session.location != null)
                              _InfoRow(
                                icon: Icons.location_on,
                                label: 'Địa điểm',
                                value: widget.session.location!,
                              ),
                            if (widget.session.description != null)
                              _InfoRow(
                                icon: Icons.description,
                                label: 'Mô tả',
                                value: widget.session.description!,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Statistics - Only for Admin/Teacher
                    if (!isStudent && _stats != null && _stats!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Thống kê điểm danh',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Có mặt',
                                value: '${_stats!['present'] ?? 0}',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Vắng',
                                value: '${_stats!['absent'] ?? 0}',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Muộn',
                                value: '${_stats!['late'] ?? 0}',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Có phép',
                                value: '${_stats!['excused'] ?? 0}',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Students List - Only for Admin/Teacher
                    if (!isStudent) ...[
                      const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách sinh viên (${_students.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _students.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: custom.EmptyWidget(
                              icon: Icons.people_outline,
                              title: 'Không có sinh viên',
                              message: 'Lớp học này chưa có sinh viên nào',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final record = _records.firstWhere(
                                (r) => r.studentId == student.id,
                                orElse: () => AttendanceRecord(
                                  sessionId: widget.session.id!,
                                  studentId: student.id!,
                                ),
                              );
                              final hasAttended = record.id != null;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          student.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                        ),
                                      ),
                                      if (hasAttended)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                  record.status),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              _getStatusIcon(record.status),
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    student.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(student.studentId),
                                  trailing: hasAttended
                                      ? Chip(
                                          label: Text(
                                            record.status.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getStatusColor(
                                                  record.status),
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(
                                                  record.status)
                                              .withOpacity(0.1),
                                          side: BorderSide.none,
                                        )
                                      : TextButton(
                                          onPressed: () =>
                                              _showAttendanceDialog(student),
                                          child: const Text('Điểm danh'),
                                        ),
                                  onTap: () => _showAttendanceDialog(student),
                                ),
                              );
                            },
                          ),
                    ],

                    // Student: Show message
                    if (isStudent) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Quét mã QR để điểm danh',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sử dụng nút quét QR ở trên để điểm danh cho buổi học này',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Color _getSessionStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.completed:
        return Colors.grey;
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

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }

  Future<void> _exportCSV() async {
    try {
      final path = await ExportService.instance
          .exportAttendanceToCSV(widget.session.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xuất CSV thành công!\nĐường dẫn: $path'),
            duration: const Duration(seconds: 3),
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
    }
  }

  Future<void> _exportPDF() async {
    try {
      final path = await ExportService.instance
          .exportAttendanceToPDF(widget.session.id!);
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xuất PDF thành công!'),
            content: Text('File đã được lưu tại:\n$path'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Đóng'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.visibility),
                label: const Text('Xem/In'),
              ),
            ],
          ),
        );

        if (result == true && mounted) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          await Printing.layoutPdf(
            onLayout: (_) async => bytes,
          );
        }
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
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

