import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
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
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final role = currentUser?.role;

      List<Subject> subjects;

      if (role == UserRole.student) {
        // Student: Get subjects by their class
        final student = await _getStudentByUser(currentUser!);
        subjects = await _db.getAllSubjects(classCode: student.classCode);
      } else if (role == UserRole.teacher) {
        // Teacher: Get only subjects they created
        final userId = await _getUserId(currentUser!);
        subjects = await _db.getSubjectsByCreator(userId);
      } else {
        // Admin: Get all subjects
        subjects = await _db.getAllSubjects();
      }

      setState(() {
        _allSubjects = subjects;
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

  Future<int> _getUserId(AppUser user) async {
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
    if (maps.isEmpty) throw Exception('User not found');
    return maps.first['id'] as int;
  }

  Future<Student> _getStudentByUser(AppUser user) async {
    final allStudents = await _db.getAllStudents();
    return allStudents.firstWhere(
      (s) => s.email.toLowerCase() == user.email.toLowerCase(),
      orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
    );
  }

  void _applyFilters() {
    List<Subject> filtered = List.from(_allSubjects);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((subject) {
        final query = _searchQuery.toLowerCase();
        return subject.subjectName.toLowerCase().contains(query) ||
            subject.subjectCode.toLowerCase().contains(query) ||
            subject.classCode.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredSubjects = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý môn học'),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm môn học...',
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

          // Subjects list
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách môn học...')
                : _filteredSubjects.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.school_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'Không tìm thấy môn học'
                            : 'Chưa có môn học nào',
                        message: _searchQuery.isNotEmpty
                            ? 'Thử tìm kiếm với từ khóa khác'
                            : 'Hãy tạo môn học đầu tiên',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = _filteredSubjects[index];
                            return _SubjectCard(
                              subject: subject,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectDetailScreen(subject: subject),
                                  ),
                                ).then((_) => _loadSubjects());
                              },
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

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.book,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          subject.subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Mã môn: ${subject.subjectCode}'),
            Text('Lớp: ${subject.classCode}'),
            if (subject.description != null) ...[
              const SizedBox(height: 4),
              Text(
                subject.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
