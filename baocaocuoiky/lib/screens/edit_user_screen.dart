import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';

class EditUserScreen extends StatefulWidget {
  final AppUser user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  UserRole? _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName;
    _emailController.text = widget.user.email;
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final oldRole = widget.user.role;
      final newRole = _selectedRole ?? widget.user.role;
      final email = _emailController.text.trim();
      final displayName = _nameController.text.trim();

      final updatedUser = widget.user.copyWith(
        displayName: displayName,
        email: email,
        role: newRole,
      );

      // Update user in users collection
      await _db.updateUser(updatedUser);

      // Handle Student record based on role change
      if (oldRole != newRole) {
        // Case 1: Changed TO Student (from Teacher/Admin)
        if (newRole == UserRole.student) {
          // Check if Student record already exists
          final existingStudent = await _db.getStudentByEmail(email);
          
          if (existingStudent == null) {
            // Create new Student record
            final studentId = 'SV${DateTime.now().millisecondsSinceEpoch % 1000000}';
            final student = Student(
              studentId: studentId,
              name: displayName,
              email: email,
              phone: null,
              classCode: null,
              subjectIds: [],
            );
            
            await _db.createStudent(student);
          }
        }
        // Case 2: Changed FROM Student (to Teacher/Admin)
        else if (oldRole == UserRole.student && newRole != UserRole.student) {
          // Find and delete Student record
          final existingStudent = await _db.getStudentByEmail(email);
          if (existingStudent != null && existingStudent.id != null) {
            await _db.deleteStudent(existingStudent.id!);
          }
        }
      } 
      // Case 3: Role is still Student, but email/name changed
      else if (newRole == UserRole.student) {
        // Update Student record if it exists
        final existingStudent = await _db.getStudentByEmail(widget.user.email);
        if (existingStudent != null) {
          final updatedStudent = existingStudent.copyWith(
            name: displayName,
            email: email,
          );
          await _db.updateStudent(updatedStudent);
        } else {
          // Student record doesn't exist, create it
          final studentId = 'SV${DateTime.now().millisecondsSinceEpoch % 1000000}';
          final student = Student(
            studentId: studentId,
            name: displayName,
            email: email,
            phone: null,
            classCode: null,
            subjectIds: [],
          );
          await _db.createStudent(student);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
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
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên',
                prefixIcon: Icons.person,
                validator: (v) => Validators.required(v, fieldName: 'Họ và tên'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Nhập email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.email(v),
              ),
              const SizedBox(height: 24),
              Text(
                'Vai trò',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              RadioListTile<UserRole>(
                title: const Text('Quản trị viên'),
                value: UserRole.admin,
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                },
              ),
              RadioListTile<UserRole>(
                title: const Text('Giáo viên'),
                value: UserRole.teacher,
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                },
              ),
              RadioListTile<UserRole>(
                title: const Text('Học sinh'),
                value: UserRole.student,
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveUser,
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
                          'Lưu thay đổi',
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

