import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../models/attendance_session.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;

class EditSubjectScreen extends StatefulWidget {
  final Subject subject;

  const EditSubjectScreen({super.key, required this.subject});

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _classCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Data
  List<AppUser> _teachers = [];
  List<Student> _allStudents = [];
  List<Student> _currentStudents = []; // Học sinh hiện tại của môn học
  List<AttendanceSession> _existingSessions = [];
  AppUser? _selectedTeacher;
  List<Student> _selectedStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _autoFillSessions = true;
  bool _isTeacher = false; // Flag to check if current user is teacher
  
  // Session dates (dynamic - có thể thêm/xóa)
  List<DateTime?> _sessionDates = [];
  List<TimeOfDay?> _sessionStartTimes = [];
  List<TimeOfDay?> _sessionEndTimes = [];
  List<int?> _sessionIds = []; // ID của session nếu đã tồn tại
  List<String> _sessionTimeSlots = []; // Ca học cho từng buổi: 'morning', 'afternoon', 'custom'

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadData();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _classCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _subjectNameController.text = widget.subject.subjectName;
    _subjectCodeController.text = widget.subject.subjectCode;
    _classCodeController.text = widget.subject.classCode;
    _descriptionController.text = widget.subject.description ?? '';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Check if current user is teacher
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      final role = currentUser?.role;
      _isTeacher = (role == UserRole.teacher);
      
      final teachers = await _db.getUsersByRole(UserRole.teacher);
      final students = await _db.getAllStudents();
      final sessions = await _db.getSessionsBySubject(widget.subject.id!);
      
      // Lấy học sinh hiện tại của môn học
      final currentStudents = students.where((s) {
        return s.subjectIds?.contains(widget.subject.id.toString()) ?? false;
      }).toList();
      
      // Load sessions vào form
      _sessionDates = sessions.map((s) => s.sessionDate).toList();
      _sessionStartTimes = sessions.map((s) {
        if (s.sessionDate != null) {
          return TimeOfDay(hour: s.sessionDate!.hour, minute: s.sessionDate!.minute);
        }
        return const TimeOfDay(hour: 7, minute: 30);
      }).toList();
      _sessionEndTimes = List.generate(sessions.length, (i) {
        // Mặc định kết thúc sau 4 giờ
        final start = _sessionStartTimes[i];
        if (start != null) {
          return TimeOfDay(hour: (start.hour + 4) % 24, minute: start.minute);
        }
        return const TimeOfDay(hour: 11, minute: 30);
      });
      _sessionIds = sessions.map((s) => s.id).toList();
      
      // Khởi tạo time slots dựa trên thời gian của session
      _sessionTimeSlots = sessions.map((s) {
        if (s.sessionDate != null) {
          final hour = s.sessionDate!.hour;
          if (hour >= 7 && hour < 12) {
            return 'morning';
          } else if (hour >= 12 && hour < 17) {
            return 'afternoon';
          }
        }
        return 'custom';
      }).toList();
      
      // Tìm giáo viên hiện tại
      AppUser? currentTeacher;
      if (widget.subject.creatorId != null && teachers.isNotEmpty) {
        try {
          currentTeacher = teachers.firstWhere(
            (t) => t.uid == widget.subject.creatorId,
          );
        } catch (e) {
          currentTeacher = teachers[0];
        }
      } else if (teachers.isNotEmpty) {
        currentTeacher = teachers[0];
      }
      
      setState(() {
        _teachers = teachers;
        _allStudents = students;
        _currentStudents = currentStudents;
        _selectedStudents = List.from(currentStudents);
        _selectedTeacher = currentTeacher ?? (teachers.isNotEmpty ? teachers[0] : null);
        _existingSessions = sessions;
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

  void _addSession() {
    setState(() {
      final now = DateTime.now();
      TimeOfDay startTime, endTime;
      String timeSlot = 'morning'; // Mặc định ca sáng
      
      startTime = const TimeOfDay(hour: 7, minute: 30);
      endTime = const TimeOfDay(hour: 11, minute: 30);
      
      if (_autoFillSessions && _sessionDates.isNotEmpty) {
        // Tự động: thêm buổi tiếp theo cách buổi cuối 7 ngày, giữ nguyên ca học của buổi cuối
        final lastDate = _sessionDates.last;
        final lastTimeSlot = _sessionTimeSlots.isNotEmpty ? _sessionTimeSlots.last : 'morning';
        timeSlot = lastTimeSlot;
        
        // Lấy thời gian từ buổi cuối
        if (_sessionStartTimes.isNotEmpty && _sessionEndTimes.isNotEmpty) {
          startTime = _sessionStartTimes.last ?? startTime;
          endTime = _sessionEndTimes.last ?? endTime;
        }
        
        if (lastDate != null) {
          _sessionDates.add(lastDate.add(const Duration(days: 7)));
        } else {
          _sessionDates.add(DateTime(
            now.year,
            now.month,
            now.day,
            startTime.hour,
            startTime.minute,
          ));
        }
      } else {
        _sessionDates.add(DateTime(
          now.year,
          now.month,
          now.day,
          startTime.hour,
          startTime.minute,
        ));
      }
      
      _sessionStartTimes.add(startTime);
      _sessionEndTimes.add(endTime);
      _sessionTimeSlots.add(timeSlot);
      _sessionIds.add(null); // Session mới chưa có ID
    });
  }
  
  void _removeSession(int index) async {
    final sessionId = _sessionIds[index];
    if (sessionId != null) {
      // Xác nhận xóa session đã tồn tại
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa buổi học này?'),
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
      
      if (confirm != true) return;
      
      try {
        await _db.deleteSession(sessionId);
        
        // Xóa khỏi _existingSessions để cập nhật maxSessionNumber
        _existingSessions.removeWhere((s) => s.id == sessionId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa buổi học')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa buổi học: $e')),
          );
        }
        return;
      }
    }
    
    setState(() {
      _sessionDates.removeAt(index);
      _sessionStartTimes.removeAt(index);
      _sessionEndTimes.removeAt(index);
      if (index < _sessionTimeSlots.length) {
        _sessionTimeSlots.removeAt(index);
      }
      _sessionIds.removeAt(index);
    });
  }
  
  void _toggleAutoFillSessions(bool value) {
    setState(() {
      _autoFillSessions = value;
      if (value && _sessionDates.isNotEmpty) {
        // Tự động fill: mỗi buổi cách nhau 7 ngày từ buổi đầu, giữ nguyên ca học của từng buổi
        final firstDate = _sessionDates[0];
        if (firstDate != null) {
          for (int i = 0; i < _sessionDates.length; i++) {
            final timeSlot = i < _sessionTimeSlots.length ? _sessionTimeSlots[i] : 'morning';
            TimeOfDay startTime, endTime;
            
            if (timeSlot == 'morning') {
              startTime = const TimeOfDay(hour: 7, minute: 30);
              endTime = const TimeOfDay(hour: 11, minute: 30);
            } else if (timeSlot == 'afternoon') {
              startTime = const TimeOfDay(hour: 12, minute: 30);
              endTime = const TimeOfDay(hour: 16, minute: 30);
            } else {
              // Custom - giữ nguyên thời gian đã chọn
              startTime = _sessionStartTimes[i] ?? const TimeOfDay(hour: 7, minute: 30);
              endTime = _sessionEndTimes[i] ?? const TimeOfDay(hour: 11, minute: 30);
            }
            
            _sessionDates[i] = DateTime(
              firstDate.year,
              firstDate.month,
              firstDate.day,
              startTime.hour,
              startTime.minute,
            ).add(Duration(days: i * 7));
            
            if (timeSlot != 'custom') {
              _sessionStartTimes[i] = startTime;
              _sessionEndTimes[i] = endTime;
            }
          }
        }
      }
    });
  }
  
  void _onSessionTimeSlotChanged(int index, String? value) {
    if (value == null) return;
    setState(() {
      if (index < _sessionTimeSlots.length) {
        _sessionTimeSlots[index] = value;
      } else {
        _sessionTimeSlots.add(value);
      }
      
      if (value == 'morning') {
        _sessionStartTimes[index] = const TimeOfDay(hour: 7, minute: 30);
        _sessionEndTimes[index] = const TimeOfDay(hour: 11, minute: 30);
      } else if (value == 'afternoon') {
        _sessionStartTimes[index] = const TimeOfDay(hour: 12, minute: 30);
        _sessionEndTimes[index] = const TimeOfDay(hour: 16, minute: 30);
      } else {
        // Custom - giữ nguyên thời gian đã chọn hoặc mặc định
        if (_sessionStartTimes[index] == null) {
          _sessionStartTimes[index] = const TimeOfDay(hour: 7, minute: 30);
        }
        if (_sessionEndTimes[index] == null) {
          _sessionEndTimes[index] = const TimeOfDay(hour: 11, minute: 30);
        }
      }
      
      // Cập nhật lại ngày nếu đã có ngày
      if (_sessionDates[index] != null && _sessionStartTimes[index] != null) {
        final date = _sessionDates[index]!;
        final startTime = _sessionStartTimes[index]!;
        _sessionDates[index] = DateTime(
          date.year,
          date.month,
          date.day,
          startTime.hour,
          startTime.minute,
        );
      }
    });
  }
  
  Future<void> _selectSessionDate(int index) async {
    final initialDate = _sessionDates[index] ?? DateTime.now().add(Duration(days: index * 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        final timeSlot = index < _sessionTimeSlots.length ? _sessionTimeSlots[index] : 'morning';
        final startTime = _sessionStartTimes[index] ?? 
            (timeSlot == 'afternoon' 
                ? const TimeOfDay(hour: 12, minute: 30)
                : const TimeOfDay(hour: 7, minute: 30));
        _sessionDates[index] = DateTime(
          picked.year,
          picked.month,
          picked.day,
          startTime.hour,
          startTime.minute,
        );
        
        if (_sessionStartTimes[index] == null) {
          if (timeSlot == 'morning') {
            _sessionStartTimes[index] = const TimeOfDay(hour: 7, minute: 30);
            _sessionEndTimes[index] = const TimeOfDay(hour: 11, minute: 30);
          } else if (timeSlot == 'afternoon') {
            _sessionStartTimes[index] = const TimeOfDay(hour: 12, minute: 30);
            _sessionEndTimes[index] = const TimeOfDay(hour: 16, minute: 30);
          } else {
            _sessionStartTimes[index] = const TimeOfDay(hour: 7, minute: 30);
            _sessionEndTimes[index] = const TimeOfDay(hour: 11, minute: 30);
          }
        }
      });
    }
  }
  
  Future<void> _selectSessionTime(int index, bool isStart) async {
    final initialTime = isStart 
        ? (_sessionStartTimes[index] ?? const TimeOfDay(hour: 7, minute: 30))
        : (_sessionEndTimes[index] ?? const TimeOfDay(hour: 11, minute: 30));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _sessionStartTimes[index] = picked;
        } else {
          _sessionEndTimes[index] = picked;
        }
        // Tự động chuyển sang custom khi chọn thời gian thủ công
        if (index < _sessionTimeSlots.length) {
          _sessionTimeSlots[index] = 'custom';
        }
      });
    }
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Only check teacher selection if not a teacher (admin can change teacher)
    if (!_isTeacher && _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giáo viên')),
      );
      return;
    }
    
    // If teacher, use current user's UID (cannot change teacher)
    final creatorId = _isTeacher 
        ? widget.subject.creatorId ?? context.read<AuthProvider>().currentUser?.uid
        : _selectedTeacher!.uid;
    
    if (creatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin giáo viên')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Cập nhật thông tin môn học
      final updatedSubject = Subject(
        id: widget.subject.id,
        subjectCode: _subjectCodeController.text.trim(),
        subjectName: _subjectNameController.text.trim(),
        classCode: _classCodeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        creatorId: creatorId,
      );

      await _db.updateSubject(updatedSubject);
      
      // 2. Cập nhật học sinh cho môn học
      // Xóa môn học khỏi học sinh không còn được chọn
      for (final student in _currentStudents) {
        if (!_selectedStudents.contains(student)) {
          final currentSubjectIds = student.subjectIds ?? [];
          final updatedSubjectIds = currentSubjectIds.where(
            (id) => id != widget.subject.id.toString()
          ).toList();
          final updatedStudent = Student(
            id: student.id,
            studentId: student.studentId,
            name: student.name,
            email: student.email,
            phone: student.phone,
            classCode: student.classCode,
            subjectIds: updatedSubjectIds,
          );
          await _db.updateStudent(updatedStudent);
        }
      }
      
      // Thêm môn học cho học sinh mới được chọn
      for (final student in _selectedStudents) {
        if (!_currentStudents.contains(student)) {
          final currentSubjectIds = student.subjectIds ?? [];
          if (!currentSubjectIds.contains(widget.subject.id.toString())) {
            final updatedSubjectIds = [...currentSubjectIds, widget.subject.id.toString()];
            final updatedStudent = Student(
              id: student.id,
              studentId: student.studentId,
              name: student.name,
              email: student.email,
              phone: student.phone,
              classCode: student.classCode,
              subjectIds: updatedSubjectIds,
            );
            await _db.updateStudent(updatedStudent);
          }
        }
      }

      // 3. Cập nhật/tạo/xóa buổi học
      // Tìm session number lớn nhất hiện có
      int maxSessionNumber = 0;
      for (final session in _existingSessions) {
        if (session.sessionNumber > maxSessionNumber) {
          maxSessionNumber = session.sessionNumber;
        }
      }
      
      int newSessionCounter = 0;
      for (int i = 0; i < _sessionDates.length; i++) {
        final sessionDate = _sessionDates[i];
        if (sessionDate == null) continue;

        final startTime = _sessionStartTimes[i] ?? const TimeOfDay(hour: 7, minute: 30);
        final sessionDateTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          startTime.hour,
          startTime.minute,
        );

        final sessionId = _sessionIds[i];
        if (sessionId != null) {
          // Cập nhật session đã tồn tại
          final existingSession = _existingSessions.firstWhere(
            (s) => s.id == sessionId,
          );
          final updatedSession = AttendanceSession(
            id: sessionId,
            sessionCode: existingSession.sessionCode,
            title: existingSession.title,
            description: existingSession.description,
            subjectId: widget.subject.id!,
            classCode: updatedSubject.classCode,
            sessionNumber: existingSession.sessionNumber,
            sessionDate: sessionDateTime,
            status: existingSession.status,
            creatorId: creatorId,
          );
          await _db.updateSession(updatedSession);
        } else {
          // Tạo session mới
          newSessionCounter++;
          final sessionNumber = maxSessionNumber + newSessionCounter;
          final session = AttendanceSession(
            sessionCode: '${updatedSubject.subjectCode}-BUOI$sessionNumber',
            title: 'Buổi $sessionNumber',
            description: 'Buổi học thứ $sessionNumber của môn ${updatedSubject.subjectName}',
            subjectId: widget.subject.id!,
            classCode: updatedSubject.classCode,
            sessionNumber: sessionNumber,
            sessionDate: sessionDateTime,
            status: SessionStatus.scheduled,
            creatorId: creatorId,
          );
          await _db.createSession(session);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật môn học thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật môn học: $e'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa môn học')),
        body: const custom.LoadingWidget(message: 'Đang tải dữ liệu...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa môn học'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin môn học
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin môn học',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên môn học *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tên môn học' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã môn học *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập mã môn học' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _classCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã lớp *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập mã lớp' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chọn giáo viên (chỉ hiển thị cho Admin, không cho Teacher chỉnh sửa)
              if (!_isTeacher) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giáo viên *',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<AppUser>(
                          value: _selectedTeacher,
                          decoration: const InputDecoration(
                            labelText: 'Chọn giáo viên',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _teachers.map((teacher) {
                            return DropdownMenuItem(
                              value: teacher,
                              child: Text(teacher.displayName),
                            );
                          }).toList(),
                          onChanged: (teacher) {
                            setState(() => _selectedTeacher = teacher);
                          },
                          validator: (v) => v == null ? 'Vui lòng chọn giáo viên' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Chọn học sinh
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học sinh',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đã chọn: ${_selectedStudents.length} học sinh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _allStudents.length,
                          itemBuilder: (context, index) {
                            final student = _allStudents[index];
                            final isSelected = _selectedStudents.contains(student);
                            
                            return CheckboxListTile(
                              title: Text(student.name),
                              subtitle: Text(student.email),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedStudents.add(student);
                                  } else {
                                    _selectedStudents.remove(student);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buổi học
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Buổi học',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            children: [
                              const Text('Tự động'),
                              Switch(
                                value: _autoFillSessions,
                                onChanged: _toggleAutoFillSessions,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Nút thêm buổi học
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addSession,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm buổi học'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_sessionDates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Chưa có buổi học nào. Nhấn "Thêm buổi học" để thêm.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...List.generate(_sessionDates.length, (index) {
                          final startTime = _sessionStartTimes[index];
                          final endTime = _sessionEndTimes[index];
                          final timeDisplay = (startTime != null && endTime != null)
                              ? '${startTime.hour.toString().padLeft(2, '0')}h${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}h${endTime.minute.toString().padLeft(2, '0')}'
                              : 'Chưa chọn';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Buổi ${index + 1}:',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeSession(index),
                                          tooltip: 'Xóa buổi học',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _selectSessionDate(index),
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'Ngày',
                                                border: OutlineInputBorder(),
                                                suffixIcon: Icon(Icons.calendar_today),
                                              ),
                                              child: Text(
                                                _sessionDates[index] != null
                                                    ? DateFormat('dd/MM/yyyy', 'vi_VN').format(_sessionDates[index]!)
                                                    : 'Chọn ngày',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Chọn ca học cho từng buổi
                                    DropdownButtonFormField<String>(
                                      value: index < _sessionTimeSlots.length ? _sessionTimeSlots[index] : 'morning',
                                      decoration: const InputDecoration(
                                        labelText: 'Ca học',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.access_time),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'morning',
                                          child: Text('Ca sáng (7h30 - 11h30)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'afternoon',
                                          child: Text('Ca chiều (12h30 - 16h30)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'custom',
                                          child: Text('Tùy chỉnh'),
                                        ),
                                      ],
                                      onChanged: (value) => _onSessionTimeSlotChanged(index, value),
                                    ),
                                    if (index < _sessionTimeSlots.length && _sessionTimeSlots[index] == 'custom') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _selectSessionTime(index, true),
                                              child: InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'Bắt đầu',
                                                  border: OutlineInputBorder(),
                                                  suffixIcon: Icon(Icons.access_time),
                                                ),
                                                child: Text(
                                                  startTime != null
                                                      ? '${startTime.hour.toString().padLeft(2, '0')}h${startTime.minute.toString().padLeft(2, '0')}'
                                                      : 'Chọn giờ',
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _selectSessionTime(index, false),
                                              child: InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'Kết thúc',
                                                  border: OutlineInputBorder(),
                                                  suffixIcon: Icon(Icons.access_time),
                                                ),
                                                child: Text(
                                                  endTime != null
                                                      ? '${endTime.hour.toString().padLeft(2, '0')}h${endTime.minute.toString().padLeft(2, '0')}'
                                                      : 'Chọn giờ',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Thời gian: $timeDisplay',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveSubject,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

