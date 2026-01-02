import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../widgets/state_widgets.dart' as custom;
import '../services/sample_data_service.dart';

class UsersManagementScreen extends StatefulWidget {
  final UserRole? filterRole; // Filter by role if provided
  
  const UsersManagementScreen({super.key, this.filterRole});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SampleDataService _sampleDataService = SampleDataService.instance;
  List<AppUser> _users = [];
  bool _isLoading = true;
  bool _isCreatingSampleData = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      List<AppUser> users;
      if (widget.filterRole != null) {
        users = await _db.getUsersByRole(widget.filterRole!);
      } else {
        users = await _db.getAllUsers();
      }
      setState(() {
        _users = users;
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

  List<AppUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Bạn có chắc muốn xóa tài khoản ${user.displayName}?'),
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

    if (confirm == true) {
      try {
        await _db.deleteUser(user.uid);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài khoản')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa tài khoản: $e')),
          );
        }
      }
    }
  }

  Future<void> _editUserRole(AppUser user) async {
    UserRole? newRole;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi vai trò'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<UserRole>(
                  title: const Text('Quản trị viên'),
                  value: UserRole.admin,
                  groupValue: newRole ?? user.role,
                  onChanged: (value) => setState(() => newRole = value),
                ),
                RadioListTile<UserRole>(
                  title: const Text('Giáo viên'),
                  value: UserRole.teacher,
                  groupValue: newRole ?? user.role,
                  onChanged: (value) => setState(() => newRole = value),
                ),
                RadioListTile<UserRole>(
                  title: const Text('Học sinh'),
                  value: UserRole.student,
                  groupValue: newRole ?? user.role,
                  onChanged: (value) => setState(() => newRole = value),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newRole != null && newRole != user.role) {
                Navigator.pop(context);
                _updateUserRole(user, newRole!);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(AppUser user, UserRole newRole) async {
    try {
      final updatedUser = user.copyWith(role: newRole);
      await _db.updateUser(updatedUser);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật vai trò')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _createSampleData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo dữ liệu mẫu'),
        content: const Text(
          'Bạn có muốn tạo dữ liệu mẫu (1 admin, 5 teacher, 15 student, 10 môn học)?\n\n'
          '⚠️ CẢNH BÁO:\n'
          '• Firebase đã chặn device này do tạo/xóa quá nhiều users\n'
          '• Nếu vẫn bị chặn, vui lòng ĐỢI 15-30 PHÚT rồi thử lại\n'
          '• Hoặc tạo users thủ công qua Firebase Console (khuyến nghị)\n'
          '• Quá trình này sẽ mất vài phút với delay lớn giữa các users\n\n'
          'Xem hướng dẫn chi tiết trong file FIREBASE_RATE_LIMIT_GUIDE.md',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vẫn tạo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCreatingSampleData = true);

    try {
      // Tạo users với delay lớn
      final teachers = await _sampleDataService.initializeSampleUsers();
      
      // Đợi 5 giây trước khi tạo subjects
      await Future.delayed(const Duration(seconds: 5));
      
      // Tạo subjects
      await _sampleDataService.initializeSampleSubjects(teachers);
      
      // Reload users list
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo dữ liệu mẫu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo dữ liệu mẫu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingSampleData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (widget.filterRole == null) // Chỉ hiện trong màn hình chính, không phải filter
            IconButton(
              icon: _isCreatingSampleData
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              onPressed: _isCreatingSampleData ? null : _createSampleData,
              tooltip: 'Tạo dữ liệu mẫu',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm',
                hintText: 'Email hoặc tên',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const custom.LoadingWidget(message: 'Đang tải...')
                : _filteredUsers.isEmpty
                    ? const custom.EmptyWidget(
                        icon: Icons.people_outline,
                        title: 'Không có tài khoản nào',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user.role),
                                  child: Text(
                                    user.displayName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  user.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    Chip(
                                      label: Text(
                                        user.role.displayName,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editUserRole(user),
                                      tooltip: 'Sửa vai trò',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteUser(user),
                                      tooltip: 'Xóa',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.teacher:
        return Colors.blue;
      case UserRole.student:
        return Colors.green;
    }
  }
}

