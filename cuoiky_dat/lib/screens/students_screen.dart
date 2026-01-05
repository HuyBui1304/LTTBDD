import 'package:flutter/material.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import 'student_form_screen.dart';
import '../services/export_service.dart';
import '../widgets/skeleton_loader.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _selectedMajor = 'Tất cả';
  int? _selectedYear;
  String _sortBy = 'name'; // 'name', 'year', 'createdAt'

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final students = await _dbHelper.getAllStudents();
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Student> filtered = List.from(_students);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.major.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Major filter
    if (_selectedMajor != 'Tất cả') {
      filtered = filtered.where((s) => s.major == _selectedMajor).toList();
    }

    // Year filter
    if (_selectedYear != null) {
      filtered = filtered.where((s) => s.year == _selectedYear).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'year':
          return b.year.compareTo(a.year);
        case 'createdAt':
          return b.createdAt.compareTo(a.createdAt);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });

    setState(() {
      _filteredStudents = filtered;
    });
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sinh viên ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteStudent(student.id!);
        _loadStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sinh viên thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
  }

  List<String> _getUniqueMajors() {
    final majors = _students.map((s) => s.major).toSet().toList()..sort();
    return ['Tất cả', ...majors];
  }

  List<int> _getUniqueYears() {
    return _students.map((s) => s.year).toSet().toList()..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sinh viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Xuất dữ liệu',
            onSelected: (value) async {
              try {
                final exportService = ExportService();
                if (value == 'csv') {
                  await exportService.exportStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất CSV thành công')),
                    );
                  }
                } else if (value == 'pdf') {
                  await exportService.exportStudentsPDF();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất PDF thành công')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xuất: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(
                children: [
                  Icon(Icons.table_chart),
                  SizedBox(width: 8),
                  Text('Xuất CSV'),
                ],
              )),
              const PopupMenuItem(value: 'pdf', child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Xuất PDF'),
                ],
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Semantics(
                  label: 'Tìm kiếm sinh viên',
                  hint: 'Nhập tên, mã SV, email hoặc ngành để tìm kiếm',
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm theo tên, mã SV, email, ngành...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMajor,
                        decoration: const InputDecoration(
                          labelText: 'Ngành',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _getUniqueMajors().map((major) {
                          return DropdownMenuItem(value: major, child: Text(major));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMajor = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Khóa',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tất cả')),
                          ..._getUniqueYears().map((year) {
                            return DropdownMenuItem<int?>(value: year, child: Text('Khóa $year'));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                        _applyFilters();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'name', child: Text('Sắp xếp theo tên')),
                        const PopupMenuItem(value: 'year', child: Text('Sắp xếp theo khóa')),
                        const PopupMenuItem(value: 'createdAt', child: Text('Sắp xếp theo ngày tạo')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Students list
          Expanded(
            child: _isLoading && _students.isEmpty
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonListTile(),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedMajor != 'Tất cả' || _selectedYear != null
                                      ? 'Không tìm thấy sinh viên nào'
                                      : 'Chưa có sinh viên nào',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStudents,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Use grid layout for tablets (width > 600)
                                if (constraints.maxWidth > 600) {
                                  return GridView.builder(
                                    cacheExtent: 500,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.5,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _filteredStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _filteredStudents[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () => _showStudentDetails(student),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      child: Text(student.name[0].toUpperCase()),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        student.name,
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    PopupMenuButton<String>(
                                                      onSelected: (value) {
                                                        if (value == 'edit') {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => StudentFormScreen(student: student),
                                                            ),
                                                          ).then((result) {
                                                            if (result == true) {
                                                              _loadStudents();
                                                            }
                                                          });
                                                        } else if (value == 'delete') {
                                                          _deleteStudent(student);
                                                        }
                                                      },
                                                      itemBuilder: (context) => [
                                                        const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                                        const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text('Mã SV: ${student.studentId}', style: const TextStyle(fontSize: 12)),
                                                Text('Ngành: ${student.major}', style: const TextStyle(fontSize: 12)),
                                                Text('Khóa: ${student.year}', style: const TextStyle(fontSize: 12)),
                                                const Spacer(),
                                                Text('Email: ${student.email}', 
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  // Use list layout for phones
                                  return ListView.builder(
                                    cacheExtent: 500,
                                    itemCount: _filteredStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _filteredStudents[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            child: Text(student.name[0].toUpperCase()),
                                          ),
                                          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Mã SV: ${student.studentId}'),
                                              Text('Ngành: ${student.major} - Khóa ${student.year}'),
                                              Text('Email: ${student.email}'),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => StudentFormScreen(student: student),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    _loadStudents();
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteStudent(student),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            _showStudentDetails(student);
                                          },
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Thêm sinh viên mới',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentFormScreen()),
            );
            if (result == true) {
              _loadStudents();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mã sinh viên', student.studentId),
              _buildDetailRow('Email', student.email),
              _buildDetailRow('Số điện thoại', student.phone),
              _buildDetailRow('Ngành', student.major),
              _buildDetailRow('Khóa', student.year.toString()),
              _buildDetailRow('Ngày tạo', student.createdAt.toString().split(' ')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentFormScreen(student: student),
                ),
              ).then((result) {
                if (result == true) {
                  _loadStudents();
                }
              });
            },
            child: const Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

