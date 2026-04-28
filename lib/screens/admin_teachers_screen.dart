import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';
import 'admin_teacher_detail_screen.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _allTeachers = [];
  List<AppUser> _filteredTeachers = [];
  Map<String, List<Subject>> _teacherSubjectsMap = {}; // teacherUid -> subjects
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
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

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await _db.getUsersByRole(UserRole.teacher);

      // Tạo map teacherUid -> subjects
      final Map<String, List<Subject>> subjectsMap = {};
      for (final teacher in teachers) {
        final subjects = await _db.getSubjectsByCreator(teacher.uid);
        subjectsMap[teacher.uid] = subjects;
      }

      setState(() {
        _allTeachers = teachers;
        _teacherSubjectsMap = subjectsMap;
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
    var filtered = _allTeachers;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by name
    filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
    
    setState(() {
      _filteredTeachers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Giáo viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
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
              hint: 'Tìm kiếm giáo viên...',
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
                ? const custom.LoadingWidget(message: 'Đang tải danh sách giáo viên...')
                : _filteredTeachers.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.school,
                        title: 'Chưa có giáo viên',
                        message: 'Danh sách giáo viên sẽ hiển thị tại đây',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _filteredTeachers[index];
                          final subjects = _teacherSubjectsMap[teacher.uid] ?? [];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminTeacherDetailScreen(
                                      teacher: teacher,
                                      subjects: subjects,
                                    ),
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
                                        teacher.displayName,
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

