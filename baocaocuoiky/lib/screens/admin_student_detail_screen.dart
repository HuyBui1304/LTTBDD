import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../providers/auth_provider.dart';
import '../models/app_user.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  final Student student;

  const AdminStudentDetailScreen({super.key, required this.student});

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final allSubjects = await _db.getAllSubjects();
      final studentSubjects = <Subject>[];
      
      if (widget.student.subjectIds != null && widget.student.subjectIds!.isNotEmpty) {
        for (final subjectIdStr in widget.student.subjectIds!) {
          try {
            final subjectId = int.parse(subjectIdStr);
            final subject = allSubjects.firstWhere(
              (s) => s.id == subjectId,
              orElse: () => throw Exception('Subject not found'),
            );
            studentSubjects.add(subject);
          } catch (_) {
            // Skip invalid subject IDs
          }
        }
      }

      setState(() {
        _subjects = studentSubjects;
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
        title: const Text('Chi tiết Sinh viên'),
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải dữ liệu...')
          : SingleChildScrollView(
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
                            'Thông tin cá nhân',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, Icons.person, 'Họ tên', widget.student.name),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.badge, 'Mã sinh viên', widget.student.studentId),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.email, 'Email', widget.student.email),
                          if (widget.student.phone != null && widget.student.phone!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(context, Icons.phone, 'Số điện thoại', widget.student.phone!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Only show "Lớp đang học" for admin, hide for teacher
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isTeacher = authProvider.currentUser?.role == UserRole.teacher;
                      
                      if (isTeacher) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lớp đang học (${_subjects.length})',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_subjects.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('Chưa có lớp học nào'),
                                    )
                                  else
                                    ..._subjects.map((subject) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.book, color: Colors.blue),
                                          ),
                                          title: Text(
                                            subject.subjectName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Mã môn: ${subject.subjectCode}'),
                                              Text('Mã lớp: ${subject.classCode}'),
                                            ],
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: Colors.grey.shade200),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
}

