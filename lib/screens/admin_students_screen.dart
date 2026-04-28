import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import 'admin_student_detail_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
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
      _applyFilters();
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      List<Student> students;
      if (currentUser?.role == UserRole.teacher) {
        // Teacher: Only load students they teach
        final teacherUid = currentUser!.uid;
        students = await _db.getStudentsByTeacher(teacherUid);
      } else {
        // Admin: Load all students
        students = await _db.getAllStudents();
      }

      setState(() {
        _allStudents = students;
        _applyFilters();
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

  void _applyFilters() {
    var filtered = _allStudents;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.studentId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by name
    filtered.sort((a, b) => a.name.compareTo(b.name));
    
    setState(() {
      _filteredStudents = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sinh viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Tìm kiếm sinh viên...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
              onClear: () {
                setState(() => _searchQuery = '');
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách sinh viên...')
                : _filteredStudents.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.people_outline,
                        title: 'Chưa có sinh viên',
                        message: 'Danh sách sinh viên sẽ hiển thị tại đây',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminStudentDetailScreen(student: student),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

