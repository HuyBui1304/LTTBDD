import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import 'student_class_attendance_history_screen.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<String> _classCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
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

      // Get class code from student (student belongs to one class)
      final classCodes = <String>[];
      if (student.classCode != null && student.classCode!.isNotEmpty) {
        classCodes.add(student.classCode!);
      }

      setState(() {
        _classCodes = classCodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lớp học'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải...')
          : _classCodes.isEmpty
              ? const custom.EmptyWidget(
                  icon: Icons.class_,
                  title: 'Chưa có lớp học nào',
                  message: 'Bạn chưa được đăng ký vào lớp nào',
                )
              : RefreshIndicator(
                  onRefresh: _loadClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classCodes.length,
                    itemBuilder: (context, index) {
                      final classCode = _classCodes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            classCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Nhấn để xem lịch sử điểm danh'),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentClassAttendanceHistoryScreen(classCode: classCode),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

