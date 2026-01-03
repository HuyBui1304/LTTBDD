import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' show AppNotification;
import '../models/app_user.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart' show UserRole;

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _targetType = 'all'; // 'all', 'role', 'user', 'class'
  UserRole? _selectedRole;
  AppUser? _selectedUser;
  String? _selectedClassCode;
  List<AppUser> _allUsers = [];
  List<Subject> _allSubjects = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set default target type for teacher after context is available
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser?.role == UserRole.teacher && _targetType == 'all') {
      _targetType = 'role';
      _selectedRole = UserRole.student;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final isTeacher = currentUser?.role == UserRole.teacher;
      
      List<AppUser> users;
      List<Subject> subjects;
      
      if (isTeacher) {
        // Teacher: Only load students they teach and subjects they teach
        final teacherUid = currentUser!.uid;
        final teacherSubjects = await _db.getSubjectsByCreator(teacherUid);
        final teacherStudents = await _db.getStudentsByTeacher(teacherUid);
        
        // Filter users to only show students
        final allUsers = await _db.getAllUsers();
        final studentUids = teacherStudents.map((s) => s.email).toSet();
        users = allUsers.where((u) => 
          u.role == UserRole.student && studentUids.contains(u.email)
        ).toList();
        
        subjects = teacherSubjects;
      } else {
        // Admin: Load all
        users = await _db.getAllUsers();
        subjects = await _db.getAllSubjects();
      }
      
      if (mounted) {
        setState(() {
          _allUsers = users;
          _allSubjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  Future<void> _saveNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final isTeacher = currentUser?.role == UserRole.teacher;
      
      String? targetRole;
      String? targetUserId;
      String? targetClassCode;

      if (_targetType == 'all_classes' && isTeacher) {
        // Teacher: Gửi đến tất cả các lớp học mà họ dạy
        // Không set targetClassCode để gửi đến tất cả các lớp
        // Sẽ filter trong logic hiển thị thông báo
        targetRole = UserRole.student.name; // Chỉ gửi đến học sinh
      } else if (_targetType == 'role') {
        if (isTeacher) {
          // Teacher chỉ có thể gửi đến học sinh
          targetRole = UserRole.student.name;
        } else if (_selectedRole != null) {
          targetRole = _selectedRole!.name;
        }
      } else if (_targetType == 'user' && _selectedUser != null) {
        targetUserId = _selectedUser!.uid;
      } else if (_targetType == 'class' && _selectedClassCode != null) {
        targetClassCode = _selectedClassCode;
      }

      if (currentUser == null) {
        throw 'Vui lòng đăng nhập lại';
      }

      // Tự động đánh dấu người tạo đã đọc thông báo
      final readBy = [currentUser.uid];

      final notification = AppNotification(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        targetRole: targetRole,
        targetUserId: targetUserId,
        targetClassCode: targetClassCode,
        readBy: readBy,
        createdAt: DateTime.now(),
        createdBy: currentUser.uid,
      );

      await _db.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thông báo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo thông báo'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Nội dung
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 24),

              // Chọn đối tượng nhận thông báo
              Text(
                'Gửi đến',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Radio buttons cho loại đối tượng
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final isTeacher = authProvider.currentUser?.role == UserRole.teacher;
                  
                  if (isTeacher) {
                    // Teacher: Chỉ có thể gửi đến tất cả các lớp học, theo lớp, hoặc theo sinh viên
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Tất cả các lớp học'),
                          subtitle: const Text('Gửi đến tất cả các lớp mà tôi dạy'),
                          value: 'all_classes',
                          groupValue: _targetType,
                          onChanged: (value) {
                            setState(() {
                              _targetType = value!;
                              _selectedRole = null;
                              _selectedUser = null;
                              _selectedClassCode = null;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Theo lớp học'),
                          value: 'class',
                          groupValue: _targetType,
                          onChanged: (value) {
                            setState(() {
                              _targetType = value!;
                              _selectedRole = null;
                              _selectedUser = null;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Theo sinh viên'),
                          value: 'user',
                          groupValue: _targetType,
                          onChanged: (value) {
                            setState(() {
                              _targetType = value!;
                              _selectedRole = null;
                              _selectedClassCode = null;
                            });
                          },
                        ),
                      ],
                    );
                  } else {
                    // Admin: Có thể gửi đến tất cả
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Tất cả người dùng'),
                          value: 'all',
                          groupValue: _targetType,
                          onChanged: (value) {
                            setState(() {
                              _targetType = value!;
                              _selectedRole = null;
                              _selectedUser = null;
                              _selectedClassCode = null;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Theo vai trò'),
                          value: 'role',
                          groupValue: _targetType,
                          onChanged: (value) {
                            setState(() {
                              _targetType = value!;
                              _selectedUser = null;
                              _selectedClassCode = null;
                            });
                          },
                        ),
                        if (_targetType == 'role') ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<UserRole>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Chọn vai trò',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            items: UserRole.values.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role.displayName),
                              );
                            }).toList(),
                            onChanged: (role) {
                              setState(() => _selectedRole = role);
                            },
                            validator: _targetType == 'role'
                                ? (v) => v == null ? 'Vui lòng chọn vai trò' : null
                                : null,
                          ),
                        ],
                      ],
                    );
                  }
                },
              ),
              // Only show "Người dùng cụ thể" for admin (teacher uses "Theo sinh viên")
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.currentUser?.role != UserRole.teacher) {
                    return RadioListTile<String>(
                      title: const Text('Người dùng cụ thể'),
                      value: 'user',
                      groupValue: _targetType,
                      onChanged: (value) {
                        setState(() {
                          _targetType = value!;
                          _selectedRole = null;
                          _selectedClassCode = null;
                        });
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_targetType == 'user') ...[
                const SizedBox(height: 8),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<AppUser>(
                        value: _selectedUser,
                        decoration: const InputDecoration(
                          labelText: 'Chọn người dùng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: _allUsers.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text('${user.displayName} (${user.email})'),
                          );
                        }).toList(),
                        onChanged: (user) {
                          setState(() => _selectedUser = user);
                        },
                        validator: _targetType == 'user'
                            ? (v) => v == null ? 'Vui lòng chọn người dùng' : null
                            : null,
                      ),
              ],
              // "Theo lớp học" is already in teacher's section, only show here for admin
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.currentUser?.role != UserRole.teacher) {
                    return RadioListTile<String>(
                      title: const Text('Theo lớp học'),
                      value: 'class',
                      groupValue: _targetType,
                      onChanged: (value) {
                        setState(() {
                          _targetType = value!;
                          _selectedRole = null;
                          _selectedUser = null;
                        });
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_targetType == 'class') ...[
                const SizedBox(height: 8),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedClassCode,
                        decoration: const InputDecoration(
                          labelText: 'Chọn lớp học',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                        items: _allSubjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject.classCode,
                            child: Text(
                              '${subject.classCode} - ${subject.subjectName}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        isExpanded: true,
                        onChanged: (classCode) {
                          setState(() => _selectedClassCode = classCode);
                        },
                        validator: _targetType == 'class'
                            ? (v) => v == null ? 'Vui lòng chọn lớp học' : null
                            : null,
                      ),
              ],
              const SizedBox(height: 32),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveNotification,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gửi thông báo',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

