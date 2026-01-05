import 'package:flutter/material.dart';
import '../models/student.dart';
import '../database/database_helper.dart';
import '../utils/validation.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _majorController = TextEditingController();
  int _selectedYear = DateTime.now().year;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _studentIdController.text = widget.student!.studentId;
      _emailController.text = widget.student!.email;
      _phoneController.text = widget.student!.phone;
      _majorController.text = widget.student!.major;
      _selectedYear = widget.student!.year;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final student = Student(
          id: widget.student?.id,
          name: _nameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          major: _majorController.text.trim(),
          year: _selectedYear,
          createdAt: widget.student?.createdAt ?? DateTime.now(),
        );

        if (widget.student == null) {
          await _dbHelper.insertStudent(student);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm sinh viên thành công')),
            );
          }
        } else {
          await _dbHelper.updateStudent(student);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật sinh viên thành công')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Thêm sinh viên' : 'Chỉnh sửa sinh viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateName(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Mã sinh viên *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateStudentId(value),
              enabled: widget.student == null, // Không cho sửa mã SV khi edit
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validation.validateEmail(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => Validation.validatePhone(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(
                labelText: 'Ngành học *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Ngành học'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Khóa *',
                border: OutlineInputBorder(),
              ),
              items: List.generate(10, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(value: year, child: Text('Khóa $year'));
              }),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveStudent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.student == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}

