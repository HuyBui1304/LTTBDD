import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../database/database_helper.dart';
import 'schedule_form_screen.dart';
import '../services/export_service.dart';
import '../widgets/skeleton_loader.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ClassSchedule> _schedules = [];
  List<ClassSchedule> _filteredSchedules = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  int? _selectedDay;
  String? _selectedSubject;
  String _sortBy = 'dayOfWeek'; // 'dayOfWeek', 'subject', 'startTime'

  final Map<int, String> _days = {
    1: 'Thứ 2',
    2: 'Thứ 3',
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    0: 'Chủ Nhật',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final schedules = await _dbHelper.getAllClassSchedules();
      setState(() {
        _schedules = schedules;
        _filteredSchedules = schedules;
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
    List<ClassSchedule> filtered = List.from(_schedules);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        return schedule.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            schedule.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            schedule.teacher.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            schedule.room.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Day filter
    if (_selectedDay != null) {
      filtered = filtered.where((s) => s.dayOfWeek == _selectedDay).toList();
    }

    // Subject filter
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      filtered = filtered.where((s) => s.subject == _selectedSubject).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'subject':
          return a.subject.compareTo(b.subject);
        case 'startTime':
          return a.startTime.compareTo(b.startTime);
        case 'dayOfWeek':
        default:
          if (a.dayOfWeek != b.dayOfWeek) {
            return a.dayOfWeek.compareTo(b.dayOfWeek);
          }
          return a.startTime.compareTo(b.startTime);
      }
    });

    setState(() {
      _filteredSchedules = filtered;
    });
  }

  Future<void> _deleteSchedule(ClassSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa lịch học ${schedule.className}?'),
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
        await _dbHelper.deleteClassSchedule(schedule.id!);
        _loadSchedules();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa lịch học thành công')),
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

  List<String> _getUniqueSubjects() {
    final subjects = _schedules.map((s) => s.subject).toSet().toList()..sort();
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch học'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Xuất dữ liệu',
            onSelected: (value) async {
              try {
                final exportService = ExportService();
                if (value == 'csv') {
                  await exportService.exportClassSchedules();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất CSV thành công')),
                    );
                  }
                } else if (value == 'pdf') {
                  await exportService.exportSchedulesPDF();
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
                  label: 'Tìm kiếm lịch học',
                  hint: 'Nhập tên lớp, môn học, giảng viên hoặc phòng để tìm kiếm',
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm theo lớp, môn học, giảng viên, phòng...',
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
                      child: DropdownButtonFormField<int?>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Thứ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tất cả')),
                          ..._days.entries.map((entry) {
                            return DropdownMenuItem<int?>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Môn học',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                          ..._getUniqueSubjects().map((subject) {
                            return DropdownMenuItem<String?>(value: subject, child: Text(subject));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value;
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
                        const PopupMenuItem(value: 'dayOfWeek', child: Text('Sắp xếp theo thứ')),
                        const PopupMenuItem(value: 'subject', child: Text('Sắp xếp theo môn học')),
                        const PopupMenuItem(value: 'startTime', child: Text('Sắp xếp theo giờ')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Schedules list
          Expanded(
            child: _isLoading && _schedules.isEmpty
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
                              onPressed: _loadSchedules,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSchedules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedDay != null || _selectedSubject != null
                                      ? 'Không tìm thấy lịch học nào'
                                      : 'Chưa có lịch học nào',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSchedules,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Use grid layout for tablets (width > 600)
                                if (constraints.maxWidth > 600) {
                                  return GridView.builder(
                                    cacheExtent: 500,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _filteredSchedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _filteredSchedules[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () => _showScheduleDetails(schedule),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                                      child: Text(
                                                        schedule.dayOfWeek.toString(),
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        schedule.className,
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
                                                              builder: (context) => ScheduleFormScreen(schedule: schedule),
                                                            ),
                                                          ).then((result) {
                                                            if (result == true) {
                                                              _loadSchedules();
                                                            }
                                                          });
                                                        } else if (value == 'delete') {
                                                          _deleteSchedule(schedule);
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
                                                Text('Môn: ${schedule.subject}', style: const TextStyle(fontSize: 12)),
                                                Text('${schedule.dayName}, ${schedule.startTime} - ${schedule.endTime}', 
                                                  style: const TextStyle(fontSize: 12)),
                                                const Spacer(),
                                                Text('Phòng: ${schedule.room}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                Text('GV: ${schedule.teacher}', 
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text('Tuần: ${schedule.weekPattern}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                                    itemCount: _filteredSchedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _filteredSchedules[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            child: Text(
                                              schedule.dayOfWeek.toString(),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                          title: Text(
                                            schedule.className,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Môn: ${schedule.subject}'),
                                              Text('${schedule.dayName}, ${schedule.startTime} - ${schedule.endTime}'),
                                              Text('Phòng: ${schedule.room} | GV: ${schedule.teacher}'),
                                              Text('Tuần: ${schedule.weekPattern}'),
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
                                                      builder: (context) => ScheduleFormScreen(schedule: schedule),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    _loadSchedules();
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteSchedule(schedule),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            _showScheduleDetails(schedule);
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
        label: 'Thêm lịch học mới',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScheduleFormScreen()),
            );
            if (result == true) {
              _loadSchedules();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showScheduleDetails(ClassSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.className),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Môn học', schedule.subject),
              _buildDetailRow('Thứ', schedule.dayName),
              _buildDetailRow('Thời gian', '${schedule.startTime} - ${schedule.endTime}'),
              _buildDetailRow('Phòng học', schedule.room),
              _buildDetailRow('Giảng viên', schedule.teacher),
              _buildDetailRow('Tuần học', schedule.weekPattern),
              _buildDetailRow('Ngày tạo', schedule.createdAt.toString().split(' ')[0]),
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
                  builder: (context) => ScheduleFormScreen(schedule: schedule),
                ),
              ).then((result) {
                if (result == true) {
                  _loadSchedules();
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

