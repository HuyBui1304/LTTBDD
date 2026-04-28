import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import 'session_detail_screen.dart';
import 'qr_scanner_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<AttendanceSession> _allSessions = [];
  List<AttendanceSession> _filteredSessions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SessionStatus? _filterStatus;
  SessionSortOption _sortOption = SessionSortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final role = currentUser?.role;
      
      List<AttendanceSession> sessions;
      
      if (role == UserRole.student) {
        // Student: Get sessions by their class
        final student = await _getStudentByUser(currentUser!);
        sessions = await _db.getSessionsByStudentClass(student.classCode ?? '');
      } else if (role == UserRole.teacher) {
        // Teacher: Get only sessions they created
        final teacherUid = currentUser!.uid; // Dùng UID trực tiếp
        sessions = await _db.getSessionsByCreator(teacherUid);
      } else {
        // Admin: Get all sessions
        sessions = await _db.getAllSessions();
      }
      
      setState(() {
        _allSessions = sessions;
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
  
  // Không cần _getUserId nữa, dùng UID trực tiếp
  
  Future<Student> _getStudentByUser(AppUser user) async {
    final allStudents = await _db.getAllStudents();
    return allStudents.firstWhere(
      (s) => s.email.toLowerCase() == user.email.toLowerCase(),
      orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
    );
  }

  void _applyFilters() {
    var filtered = _allSessions;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.sessionCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.classCode.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((s) => s.status == _filterStatus).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SessionSortOption.dateDesc:
        filtered.sort((a, b) {
          if (a.sessionDate == null && b.sessionDate == null) return 0;
          if (a.sessionDate == null) return 1;
          if (b.sessionDate == null) return -1;
          return b.sessionDate!.compareTo(a.sessionDate!);
        });
        break;
      case SessionSortOption.dateAsc:
        filtered.sort((a, b) {
          if (a.sessionDate == null && b.sessionDate == null) return 0;
          if (a.sessionDate == null) return 1;
          if (b.sessionDate == null) return -1;
          return a.sessionDate!.compareTo(b.sessionDate!);
        });
        break;
      case SessionSortOption.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SessionSortOption.titleDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _showAddEditDialog({AttendanceSession? session}) {
    final isEdit = session != null;
    final formKey = GlobalKey<FormState>();
    final sessionCodeController = TextEditingController(text: session?.sessionCode ?? '');
    final titleController = TextEditingController(text: session?.title ?? '');
    final descriptionController = TextEditingController(text: session?.description ?? '');
    final classCodeController = TextEditingController(text: session?.classCode ?? '');
    final locationController = TextEditingController(text: session?.location ?? '');
    DateTime selectedDate = session?.sessionDate ?? DateTime.now();
    SessionStatus selectedStatus = session?.status ?? SessionStatus.scheduled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa buổi học' : 'Thêm buổi học'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: sessionCodeController,
                    label: 'Mã buổi học',
                    prefixIcon: Icons.qr_code,
                    validator: Validators.sessionCode,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: titleController,
                    label: 'Tiêu đề',
                    prefixIcon: Icons.title,
                    validator: (v) => Validators.required(v, fieldName: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Mô tả (tùy chọn)',
                    prefixIcon: Icons.description,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: classCodeController,
                    label: 'Mã lớp',
                    prefixIcon: Icons.class_,
                    validator: Validators.classCode,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: locationController,
                    label: 'Địa điểm (tùy chọn)',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Ngày học'),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SessionStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    items: SessionStatus.values
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedStatus = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // NOTE: Logic mới - sessions được tạo tự động khi tạo Subject
                    // Tạm thời disable create new session
                    // TODO: Implement Subject creation screen instead
                    if (!isEdit) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng tạo Lớp học phần (Subject) để tự động tạo 9 buổi học'),
                          ),
                        );
                      }
                      Navigator.pop(context);
                      return;
                    }
                    final newSession = session.copyWith(
                      sessionCode: sessionCodeController.text.trim(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      classCode: classCodeController.text.trim(),
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      sessionDate: selectedDate,
                      status: selectedStatus,
                      updatedAt: DateTime.now(),
                    );

                    if (isEdit) {
                      await _db.updateSession(newSession);
                    } else {
                      await _db.createSession(newSession);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit
                              ? 'Cập nhật buổi học thành công'
                              : 'Thêm buổi học thành công'),
                        ),
                      );
                    }
                    _loadSessions();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc và sắp xếp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lọc theo trạng thái:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    setState(() => _filterStatus = null);
                    Navigator.pop(context);
                    _applyFilters();
                  },
                ),
                ...SessionStatus.values.map((status) => FilterChip(
                      label: Text(status.displayName),
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setState(() => _filterStatus = selected ? status : null);
                        Navigator.pop(context);
                        _applyFilters();
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Sắp xếp theo:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...SessionSortOption.values.map(
              (option) => RadioListTile<SessionSortOption>(
                title: Text(option.displayName),
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.pop(context);
                  _applyFilters();
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(AttendanceSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa buổi học "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteSession(session.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa buổi học')),
          );
        }
        _loadSessions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý buổi học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Tìm kiếm buổi học...',
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
          if (_filterStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text('Trạng thái: ${_filterStatus!.displayName}'),
                onDeleted: () {
                  setState(() => _filterStatus = null);
                  _applyFilters();
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải buổi học...')
                : _filteredSessions.isEmpty
                    ? custom.EmptyWidget(
                        icon: Icons.event_busy,
                        title: _searchQuery.isEmpty && _filterStatus == null
                            ? 'Chưa có buổi học nào'
                            : 'Không tìm thấy buổi học',
                        message: _searchQuery.isEmpty && _filterStatus == null
                            ? 'Hãy tạo buổi học đầu tiên'
                            : 'Thử tìm kiếm với từ khóa khác',
                        action: _searchQuery.isEmpty && _filterStatus == null
                            ? FilledButton.icon(
                                onPressed: () => _showAddEditDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Tạo buổi học'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(session.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.event,
                                    color: _getStatusColor(session.status),
                                  ),
                                ),
                                title: Text(
                                  session.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${session.classCode} • ${session.sessionDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!) : 'Chưa có ngày'}',
                                    ),
                                    if (session.creatorName != null)
                                      Consumer<AuthProvider>(
                                        builder: (context, authProvider, _) {
                                          if (authProvider.isAdmin) {
                                            return Text(
                                              'Người tạo: ${session.creatorName}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                  ],
                                ),
                                isThreeLine: session.creatorName != null,
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Sửa'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Xóa',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditDialog(session: session);
                                    } else if (value == 'delete') {
                                      _deleteSession(session);
                                    }
                                  },
                                ),
                                onTap: () {
                                  // Student: Chỉ cho quét QR, không cho vào chi tiết
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  if (authProvider.isStudent) {
                                    // Navigate to QR Scanner directly
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QRScannerScreen(session: session),
                                      ),
                                    );
                                  } else {
                                    // Admin/Teacher: Vào chi tiết như bình thường
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SessionDetailScreen(session: session),
                                      ),
                                    ).then((_) => _loadSessions());
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.completed:
        return Colors.grey;
    }
  }
}

enum SessionSortOption {
  dateDesc,
  dateAsc,
  titleAsc,
  titleDesc,
}

extension SessionSortOptionExtension on SessionSortOption {
  String get displayName {
    switch (this) {
      case SessionSortOption.dateDesc:
        return 'Ngày mới nhất';
      case SessionSortOption.dateAsc:
        return 'Ngày cũ nhất';
      case SessionSortOption.titleAsc:
        return 'Tên A-Z';
      case SessionSortOption.titleDesc:
        return 'Tên Z-A';
    }
  }
}

