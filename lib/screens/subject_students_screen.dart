import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';
import 'student_detail_screen.dart';

class SubjectStudentsScreen extends StatefulWidget {
  final Subject subject;

  const SubjectStudentsScreen({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectStudentsScreen> createState() => _SubjectStudentsScreenState();
}

class _SubjectStudentsScreenState extends State<SubjectStudentsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  List<Student> _displayedStudents = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAsc;
  
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      // Lấy sinh viên theo classCode của môn học
      final students = await _db.getStudentsByClass(widget.subject.classCode);
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
          s.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.studentIdAsc:
        filtered.sort((a, b) => a.studentId.compareTo(b.studentId));
        break;
      case SortOption.studentIdDesc:
        filtered.sort((a, b) => b.studentId.compareTo(a.studentId));
        break;
      case SortOption.dateNew:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateOld:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    setState(() {
      _filteredStudents = filtered;
      _currentPage = 0;
      _loadPage();
    });
  }

  void _loadPage() {
    final endIndex = (_currentPage + 1) * _pageSize;
    setState(() {
      _displayedStudents = _filteredStudents.take(endIndex).toList();
    });
  }

  Future<void> _loadMoreStudents() async {
    if (_isLoadingMore) return;
    if (_displayedStudents.length >= _filteredStudents.length) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _currentPage++;
      _loadPage();
      _isLoadingMore = false;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp xếp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values.map((option) {
            return RadioListTile<SortOption>(
              title: Text(option.displayName),
              value: option,
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() => _sortOption = value!);
                Navigator.pop(context);
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sinh viên - ${widget.subject.subjectName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sắp xếp',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.class_,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject.subjectName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Lớp: ${widget.subject.classCode}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${_filteredStudents.length} SV'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          
          const SizedBox(height: 8),
          
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải danh sách sinh viên...')
                : _filteredStudents.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.people_outline,
                        title: _searchQuery.isNotEmpty
                            ? 'Không tìm thấy sinh viên'
                            : 'Chưa có sinh viên nào',
                        message: _searchQuery.isNotEmpty
                            ? 'Thử tìm kiếm với từ khóa khác'
                            : 'Môn học này chưa có sinh viên',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _displayedStudents.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayedStudents.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final student = _displayedStudents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    student.name.isNotEmpty
                                        ? student.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    Text('Email: ${student.email}'),
                                    if (student.classCode != null)
                                      Text('Lớp: ${student.classCode}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentDetailScreen(student: student),
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

enum SortOption {
  nameAsc,
  nameDesc,
  studentIdAsc,
  studentIdDesc,
  dateNew,
  dateOld,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.nameAsc:
        return 'Tên A-Z';
      case SortOption.nameDesc:
        return 'Tên Z-A';
      case SortOption.studentIdAsc:
        return 'Mã SV tăng dần';
      case SortOption.studentIdDesc:
        return 'Mã SV giảm dần';
      case SortOption.dateNew:
        return 'Mới nhất';
      case SortOption.dateOld:
        return 'Cũ nhất';
    }
  }
}

