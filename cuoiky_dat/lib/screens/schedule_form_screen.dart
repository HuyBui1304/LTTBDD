import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../database/database_helper.dart';
import '../utils/validation.dart';

class ScheduleFormScreen extends StatefulWidget {
  final ClassSchedule? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  int _selectedDay = 1; // Monday
  String _selectedWeekPattern = 'All';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
    if (widget.schedule != null) {
      _classNameController.text = widget.schedule!.className;
      _subjectController.text = widget.schedule!.subject;
      _roomController.text = widget.schedule!.room;
      _teacherController.text = widget.schedule!.teacher;
      _startTimeController.text = widget.schedule!.startTime;
      _endTimeController.text = widget.schedule!.endTime;
      _selectedDay = widget.schedule!.dayOfWeek;
      _selectedWeekPattern = widget.schedule!.weekPattern;
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      // Validate end time is after start time
      final startParts = _startTimeController.text.split(':');
      final endParts = _endTimeController.text.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu')),
        );
        return;
      }

      try {
        final schedule = ClassSchedule(
          id: widget.schedule?.id,
          className: _classNameController.text.trim(),
          subject: _subjectController.text.trim(),
          room: _roomController.text.trim(),
          teacher: _teacherController.text.trim(),
          dayOfWeek: _selectedDay,
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          weekPattern: _selectedWeekPattern,
          createdAt: widget.schedule?.createdAt ?? DateTime.now(),
        );

        if (widget.schedule == null) {
          await _dbHelper.insertClassSchedule(schedule);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm lịch học thành công')),
            );
          }
        } else {
          await _dbHelper.updateClassSchedule(schedule);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật lịch học thành công')),
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
        title: Text(widget.schedule == null ? 'Thêm lịch học' : 'Chỉnh sửa lịch học'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Tên lớp *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Tên lớp'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Môn học *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Môn học'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Phòng học *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Phòng học'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Giảng viên *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Giảng viên'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Thứ trong tuần *',
                border: OutlineInputBorder(),
              ),
              items: _days.entries.map((entry) {
                return DropdownMenuItem(value: entry.key, child: Text(entry.value));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ bắt đầu *',
                      border: OutlineInputBorder(),
                      hintText: 'HH:mm',
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_startTimeController),
                    validator: (value) => Validation.validateTime(value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ kết thúc *',
                      border: OutlineInputBorder(),
                      hintText: 'HH:mm',
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_endTimeController),
                    validator: (value) => Validation.validateTime(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWeekPattern,
              decoration: const InputDecoration(
                labelText: 'Tuần học *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('Tất cả các tuần')),
                DropdownMenuItem(value: 'Odd', child: Text('Tuần lẻ')),
                DropdownMenuItem(value: 'Even', child: Text('Tuần chẵn')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedWeekPattern = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.schedule == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}

