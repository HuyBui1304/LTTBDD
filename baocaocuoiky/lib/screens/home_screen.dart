import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'students_screen.dart';
import 'subjects_screen.dart';
import 'export_screen.dart';
import 'users_management_screen.dart';
import 'student_attendance_screen.dart';
import 'login_screen.dart';
import 'admin_students_screen.dart';
import 'admin_teachers_screen.dart';
import 'admin_subjects_screen.dart';
import 'add_subject_screen.dart';
import 'add_user_screen.dart';
import 'notifications_screen.dart';
import 'user_notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  int _totalStudents = 0;
  int _totalSessions = 0;
  int _totalTeachers = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final role = currentUser?.role;

      if (role == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Load data based on role
      if (role == UserRole.student) {
        // Student: Load own attendance history (only their class)
        await _loadStudentData(currentUser!);
        await _loadNotificationsCount(currentUser);
      } else if (role == UserRole.teacher) {
        // Teacher: Load subjects and students they teach
        final teacherUid = currentUser!.uid; // Dùng UID trực tiếp
        final subjects = await _db.getSubjectsByCreator(teacherUid);
        final students = await _db.getStudentsByTeacher(teacherUid); // Chỉ xem students mà teacher dạy

        if (mounted) {
          setState(() {
            _totalStudents = students.length;
            _totalSessions = subjects.length; // Số môn học
            _isLoading = false;
          });
        }
        await _loadNotificationsCount(currentUser);
      } else {
        // Admin: Load all data
        final students = await _db.getAllStudents();
        final subjects = await _db.getAllSubjects();
        final teachers = await _db.getUsersByRole(UserRole.teacher);

        if (mounted) {
          setState(() {
            _totalStudents = students.length;
            _totalSessions = subjects.length; // Số môn học
            _totalTeachers = teachers.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentData(AppUser user) async {
    // Get student by email
    final allStudents = await _db.getAllStudents();
    final student = allStudents.firstWhere(
      (s) => s.email.toLowerCase() == user.email.toLowerCase(),
      orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
    );

    // Get all sessions for student's class
    final classSessions = await _db.getSessionsByStudentClass(student.classCode ?? '');

    // Get attendance records for this student
    final allRecords = <AttendanceRecord>[];
    for (final session in classSessions) {
      if (!mounted) return; // Check mounted in loop
      if (session.id != null) {
        final record = await _db.getRecordBySessionAndStudent(
          session.id!,
          student.id!,
        );
        if (record != null) {
          allRecords.add(record);
        }
      }
    }

    if (mounted) {
      setState(() {
        _totalStudents = 1; // Show as "1" (self)
        _totalSessions = classSessions.length;
        _isLoading = false;
      });
    }
  }

  // Không cần _getUserId nữa, dùng UID trực tiếp

  Future<void> _loadNotificationsCount(AppUser user) async {
    try {
      // Lấy classCodes của user
      List<String>? userClassCodes;
      
      if (user.role == UserRole.student) {
        // Student: Lấy classCodes từ subjects mà student học
        final allStudents = await _db.getAllStudents();
        final student = allStudents.firstWhere(
          (s) => s.email.toLowerCase() == user.email.toLowerCase(),
          orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
        );
        
        if (student.subjectIds != null && student.subjectIds!.isNotEmpty) {
          final allSubjects = await _db.getAllSubjects();
          userClassCodes = allSubjects
              .where((s) => student.subjectIds!.contains(s.id.toString()))
              .map((s) => s.classCode)
              .toList();
        }
      } else if (user.role == UserRole.teacher) {
        // Teacher: Lấy classCodes từ subjects mà teacher dạy
        final subjects = await _db.getSubjectsByCreator(user.uid);
        userClassCodes = subjects.map((s) => s.classCode).toList();
      }
      
      final notifications = await _db.getNotificationsForUser(
        userId: user.uid,
        userRole: user.role.name,
        userClassCodes: userClassCodes,
      );
      
      final unreadCount = notifications.where((n) {
        return n.readBy == null || !n.readBy!.contains(user.uid);
      }).length;
      
      if (mounted) {
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải số thông báo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const custom.LoadingWidget(message: 'Đang tải dữ liệu...')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Điểm danh QR',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                                      .format(DateTime.now()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                final user = authProvider.currentUser;
                                return PopupMenuButton(
                                  icon: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user?.displayName ?? 'User',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            user?.email ?? '',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          if (user != null) ...[
                                            const SizedBox(height: 4),
                                            Chip(
                                              label: Text(
                                                user.role.displayName,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor: user.isAdmin
                                                  ? Colors.red.shade100
                                                  : user.isTeacher
                                                      ? Colors.blue.shade100
                                                      : Colors.green.shade100,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'theme',
                                      child: Consumer<ThemeProvider>(
                                        builder: (context, themeProvider, _) {
                                          return Row(
                                            children: [
                                              Icon(
                                                themeProvider.isDarkMode
                                                    ? Icons.dark_mode
                                                    : Icons.light_mode,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                themeProvider.isDarkMode
                                                    ? 'Chế độ sáng'
                                                    : 'Chế độ tối',
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    if (authProvider.isAdmin)
                                      PopupMenuItem(
                                        value: 'manage_users',
                                        child: const Row(
                                          children: [
                                            Icon(Icons.people),
                                            SizedBox(width: 12),
                                            Text('Quản lý tài khoản'),
                                          ],
                                        ),
                                      ),
                                    if (authProvider.isAdmin) const PopupMenuDivider(),
                                    if (authProvider.isTeacher || authProvider.isAdmin)
                                      const PopupMenuItem(
                                        value: 'export',
                                        child: Row(
                                          children: [
                                            Icon(Icons.file_download),
                                            SizedBox(width: 12),
                                            Text('Xuất dữ liệu'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          Icon(Icons.logout, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Đăng xuất',
                                              style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'logout') {
                                      await authProvider.signOut();
                                      if (context.mounted) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen()),
                                          (route) => false,
                                        );
                                      }
                                    } else if (value == 'theme') {
                                      final themeProvider = context.read<ThemeProvider>();
                                      await themeProvider.toggleTheme();
                                    } else if (value == 'manage_users') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const UsersManagementScreen(),
                                        ),
                                      );
                                    } else if (value == 'export') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ExportScreen(),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                              ],
                            ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content based on role
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  final role = authProvider.currentUser?.role;
                                  
                                  if (role == UserRole.student) {
                                    // Student: Simple interface with 2 main actions
                                    return SliverToBoxAdapter(
                                      child: _buildStudentHome(context),
                                    );
                                  } else {
                                    // Admin/Teacher: Stats and actions
                                    return SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          _buildStatsCards(context, role),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _navigateToStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentsScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubjectsScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToAdminStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminStudentsScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToAdminTeachers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminTeachersScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToAdminSubjects() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSubjectsScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToAddSubject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSubjectScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserScreen()),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }


  // Build student home interface
  Widget _buildStudentHome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Điểm danh button
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentAttendanceScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm danh',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhập mã 4 số hoặc quét QR',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Thông báo card
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserNotificationsScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    final authProvider = context.read<AuthProvider>();
                    final currentUser = authProvider.currentUser;
                    if (currentUser != null) {
                      _loadNotificationsCount(currentUser);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông báo',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _unreadNotifications > 0
                                ? '$_unreadNotifications thông báo chưa đọc'
                                : 'Không có thông báo mới',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Môn học card
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubjectsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Môn học',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Xem các môn học của tôi',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build stats cards based on role
  Widget _buildStatsCards(BuildContext context, UserRole? role) {
    if (role == UserRole.teacher) {
      // Teacher: Show management stats (similar to admin but without some cards)
      return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          if (isTablet) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sinh viên',
                      value: '$_totalStudents',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      onTap: () => _navigateToAdminStudents(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Môn học',
                      value: '$_totalSessions',
                      icon: Icons.book,
                      color: Colors.green,
                      onTap: () => _navigateToAdminSubjects(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _StatCard(
                    title: 'Sinh viên',
                    value: '$_totalStudents',
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    onTap: () => _navigateToAdminStudents(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Môn học',
                    value: '$_totalSessions',
                    icon: Icons.book,
                    color: Colors.green,
                    onTap: () => _navigateToAdminSubjects(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Thông báo',
                    value: _unreadNotifications > 0 ? '$_unreadNotifications' : '',
                    icon: Icons.notifications,
                    color: Colors.red,
                    badgeCount: _unreadNotifications > 0 ? _unreadNotifications : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserNotificationsScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          final authProvider = context.read<AuthProvider>();
                          final currentUser = authProvider.currentUser;
                          if (currentUser != null) {
                            _loadNotificationsCount(currentUser);
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      // Admin: Show management stats with teachers
      return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          if (isTablet) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sinh viên',
                      value: '$_totalStudents',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      onTap: () => _navigateToAdminStudents(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Giáo viên',
                      value: '$_totalTeachers',
                      icon: Icons.school,
                      color: Colors.purple,
                      onTap: () => _navigateToAdminTeachers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Môn học',
                      value: '$_totalSessions',
                      icon: Icons.book,
                      color: Colors.green,
                      onTap: () => _navigateToAdminSubjects(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _StatCard(
                    title: 'Sinh viên',
                    value: '$_totalStudents',
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    onTap: () => _navigateToAdminStudents(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Giáo viên',
                    value: '$_totalTeachers',
                    icon: Icons.school,
                    color: Colors.purple,
                    onTap: () => _navigateToAdminTeachers(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Môn học',
                    value: '$_totalSessions',
                    icon: Icons.book,
                    color: Colors.green,
                    onTap: () => _navigateToAdminSubjects(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Thêm môn học',
                    value: '',
                    icon: Icons.add_circle_outline,
                    color: Colors.orange,
                    onTap: () => _navigateToAddSubject(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Thêm tài khoản',
                    value: '',
                    icon: Icons.person_add,
                    color: Colors.teal,
                    onTap: () => _navigateToAddUser(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Thông báo',
                    value: '',
                    icon: Icons.notifications,
                    color: Colors.red,
                    onTap: () => _navigateToNotifications(),
                  ),
                ],
              ),
            );
          }
        },
      );
    }
  }

}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount; // Số thông báo chưa đọc

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
                    ),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badgeCount! > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (value.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}