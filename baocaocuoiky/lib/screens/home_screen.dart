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
import 'student_classes_screen.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final role = currentUser?.role;

      if (role == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load data based on role
      if (role == UserRole.student) {
        // Student: Load own attendance history (only their class)
        await _loadStudentData(currentUser!);
      } else if (role == UserRole.teacher) {
        // Teacher: Load only sessions they created
        final userId = await _getUserId(currentUser!);
        final sessions = await _db.getSessionsByCreator(userId);
        final students = await _db.getAllStudents(); // Teachers can see all students

                                        setState(() {
          _totalStudents = students.length;
          _totalSessions = sessions.length;
          _isLoading = false;
        });
      } else {
        // Admin: Load all data
        final students = await _db.getAllStudents();
        final sessions = await _db.getAllSessions();
        final teachers = await _db.getUsersByRole(UserRole.teacher);

        setState(() {
          _totalStudents = students.length;
          _totalSessions = sessions.length;
          _totalTeachers = teachers.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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

    setState(() {
      _totalStudents = 1; // Show as "1" (self)
      _totalSessions = classSessions.length;
      _isLoading = false;
    });
  }

  Future<int> _getUserId(AppUser user) async {
    final dbUser = await _db.getUserByUid(user.uid);
    if (dbUser == null) throw Exception('User not found in database');
    // Get numeric ID from database
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
    if (maps.isEmpty) throw Exception('User not found');
    return maps.first['id'] as int;
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
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final role = authProvider.currentUser?.role;
          
          // Only show FAB for Admin/Teacher
          if (role == UserRole.student) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () => _navigateToSessions(),
            icon: const Icon(Icons.add),
            label: const Text('Quản lý môn học'),
          );
        },
      ),
    );
  }

  void _navigateToStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentsScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubjectsScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToTeachers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsersManagementScreen(filterRole: UserRole.teacher),
      ),
    ).then((_) => _loadData());
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
          // Lớp học button
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentClassesScreen(),
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
                        Icons.class_,
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
                            'Lớp học',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Xem lịch sử điểm danh',
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
      // Teacher: Show management stats
      return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          if (isTablet) {
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sinh viên',
                    value: '',
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    onTap: () => _navigateToStudents(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Quản lý môn học',
                    value: '',
                    icon: Icons.event_note,
                    color: Colors.green,
                    onTap: () => _navigateToSessions(),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Sinh viên',
                        value: '$_totalStudents',
                        icon: Icons.people_outline,
                        color: Colors.blue,
                        onTap: () => _navigateToStudents(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Quản lý môn học',
                        value: '$_totalSessions',
                        icon: Icons.event_note,
                        color: Colors.green,
                        onTap: () => _navigateToSessions(),
                      ),
                    ),
                  ],
                ),
              ],
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
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sinh viên',
                    value: '$_totalStudents',
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    onTap: () => _navigateToStudents(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Giáo viên',
                    value: '$_totalTeachers',
                    icon: Icons.school,
                    color: Colors.purple,
                    onTap: () => _navigateToTeachers(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Quản lý môn học',
                    value: '$_totalSessions',
                    icon: Icons.event_note,
                    color: Colors.green,
                    onTap: () => _navigateToSessions(),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Sinh viên',
                        value: '$_totalStudents',
                        icon: Icons.people_outline,
                        color: Colors.blue,
                        onTap: () => _navigateToStudents(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Giáo viên',
                        value: '$_totalTeachers',
                        icon: Icons.school,
                        color: Colors.purple,
                        onTap: () => _navigateToTeachers(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Quản lý môn học',
                  value: '',
                  icon: Icons.event_note,
                  color: Colors.green,
                  fullWidth: true,
                  onTap: () => _navigateToSessions(),
                ),
              ],
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
  final bool fullWidth;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              if (value.isNotEmpty) ...[
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool fullWidth;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.fullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


