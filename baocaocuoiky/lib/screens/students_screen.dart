import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';
import 'subject_students_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Subject> _allSubjects = [];
  List<Subject> _filteredSubjects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
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

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _db.getAllSubjects();
      final allStudents = await _db.getAllStudents();
      
      // Chỉ lấy những môn học có sinh viên (classCode trùng với student.classCode)
      final subjectsWithStudents = subjects.where((subject) {
        return allStudents.any((student) => student.classCode == subject.classCode);
      }).toList();
      
      setState(() {
        _allSubjects = subjectsWithStudents;
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
    var filtered = _allSubjects;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.classCode.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by subject name
    filtered.sort((a, b) => a.subjectName.compareTo(b.subjectName));
    
    setState(() {
      _filteredSubjects = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubjects,
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
              hint: 'Tìm kiếm môn học...',
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
                ? const custom.LoadingWidget(message: 'Đang tải danh sách môn học...')
                : _filteredSubjects.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.class_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'Không tìm thấy môn học'
                            : 'Chưa có môn học nào',
                        message: _searchQuery.isNotEmpty
                            ? 'Thử tìm kiếm với từ khóa khác'
                            : 'Chưa có môn học trong hệ thống',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubjects,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                          itemCount: _filteredSubjects.length,
                            itemBuilder: (context, index) {
                            final subject = _filteredSubjects[index];
                              return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.class_,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  subject.subjectName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                    const SizedBox(height: 4),
                                    Text('Mã môn: ${subject.subjectCode}'),
                                    Text('Lớp: ${subject.classCode}'),
                                        ],
                                      ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubjectStudentsScreen(subject: subject),
                                    ),
                                  );
                                },
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
