import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';

class SeedDataService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> seedData() async {
    // Check if data already exists
    final existingStudents = await _dbHelper.getAllStudents();
    if (existingStudents.isNotEmpty) {
      return; // Data already exists
    }

    // Seed students
    final students = _getSampleStudents();
    for (final student in students) {
      await _dbHelper.insertStudent(student);
    }

    // Seed class schedules
    final schedules = _getSampleSchedules();
    for (final schedule in schedules) {
      await _dbHelper.insertClassSchedule(schedule);
    }
  }

  Future<void> clearAndReseed() async {
    final db = await _dbHelper.database;
    await db.delete('students');
    await db.delete('class_schedules');
    await db.delete('audit_log');
    await seedData();
  }

  List<Student> _getSampleStudents() {
    final now = DateTime.now();
    return [
      Student(
        name: 'Nguyễn Văn An',
        studentId: 'SV2024001',
        email: 'nguyenvanan@example.com',
        phone: '0912345678',
        major: 'Công nghệ thông tin',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Student(
        name: 'Trần Thị Bình',
        studentId: 'SV2024002',
        email: 'tranthibinh@example.com',
        phone: '0923456789',
        major: 'Công nghệ thông tin',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Student(
        name: 'Lê Văn Cường',
        studentId: 'SV2024003',
        email: 'levancuong@example.com',
        phone: '0934567890',
        major: 'Kinh tế',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      Student(
        name: 'Phạm Thị Dung',
        studentId: 'SV2024004',
        email: 'phamthidung@example.com',
        phone: '0945678901',
        major: 'Kinh tế',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      Student(
        name: 'Hoàng Văn Đức',
        studentId: 'SV2023001',
        email: 'hoangvanduc@example.com',
        phone: '0956789012',
        major: 'Công nghệ thông tin',
        year: 2023,
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      Student(
        name: 'Vũ Thị Em',
        studentId: 'SV2023002',
        email: 'vuthiem@example.com',
        phone: '0967890123',
        major: 'Kinh tế',
        year: 2023,
        createdAt: now.subtract(const Duration(days: 395)),
      ),
      Student(
        name: 'Đặng Văn Phong',
        studentId: 'SV2023003',
        email: 'dangvanphong@example.com',
        phone: '0978901234',
        major: 'Điện tử',
        year: 2023,
        createdAt: now.subtract(const Duration(days: 390)),
      ),
      Student(
        name: 'Bùi Thị Giang',
        studentId: 'SV2022001',
        email: 'buithigiang@example.com',
        phone: '0989012345',
        major: 'Công nghệ thông tin',
        year: 2022,
        createdAt: now.subtract(const Duration(days: 750)),
      ),
      Student(
        name: 'Ngô Văn Hùng',
        studentId: 'SV2022002',
        email: 'ngovanhung@example.com',
        phone: '0990123456',
        major: 'Điện tử',
        year: 2022,
        createdAt: now.subtract(const Duration(days: 745)),
      ),
      Student(
        name: 'Đỗ Thị Lan',
        studentId: 'SV2024005',
        email: 'dothilan@example.com',
        phone: '0901234567',
        major: 'Kinh tế',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Student(
        name: 'Lý Văn Minh',
        studentId: 'SV2024006',
        email: 'lyvanminh@example.com',
        phone: '0911111111',
        major: 'Công nghệ thông tin',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Student(
        name: 'Võ Thị Nga',
        studentId: 'SV2023004',
        email: 'vothinga@example.com',
        phone: '0922222222',
        major: 'Kinh tế',
        year: 2023,
        createdAt: now.subtract(const Duration(days: 380)),
      ),
      Student(
        name: 'Phan Văn Quân',
        studentId: 'SV2022003',
        email: 'phanvanquan@example.com',
        phone: '0933333333',
        major: 'Điện tử',
        year: 2022,
        createdAt: now.subtract(const Duration(days: 740)),
      ),
      Student(
        name: 'Trương Thị Hoa',
        studentId: 'SV2024007',
        email: 'truongthihoa@example.com',
        phone: '0944444444',
        major: 'Công nghệ thông tin',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Student(
        name: 'Lưu Văn Sơn',
        studentId: 'SV2024008',
        email: 'luuvanson@example.com',
        phone: '0955555555',
        major: 'Công nghệ thông tin',
        year: 2024,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<ClassSchedule> _getSampleSchedules() {
    final now = DateTime.now();
    return [
      ClassSchedule(
        className: 'LTHDT-K24',
        subject: 'Lập trình hướng đối tượng',
        room: 'A101',
        teacher: 'Nguyễn Văn Hải',
        dayOfWeek: 2, // Thứ 3
        startTime: '08:00',
        endTime: '10:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ClassSchedule(
        className: 'LTHDT-K24',
        subject: 'Lập trình hướng đối tượng',
        room: 'A101',
        teacher: 'Nguyễn Văn Hải',
        dayOfWeek: 4, // Thứ 5
        startTime: '08:00',
        endTime: '10:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ClassSchedule(
        className: 'CSDL-K24',
        subject: 'Cơ sở dữ liệu',
        room: 'B202',
        teacher: 'Trần Thị Mai',
        dayOfWeek: 1, // Thứ 2
        startTime: '13:00',
        endTime: '15:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      ClassSchedule(
        className: 'CSDL-K24',
        subject: 'Cơ sở dữ liệu',
        room: 'B202',
        teacher: 'Trần Thị Mai',
        dayOfWeek: 3, // Thứ 4
        startTime: '13:00',
        endTime: '15:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      ClassSchedule(
        className: 'WEB-K24',
        subject: 'Lập trình Web',
        room: 'C301',
        teacher: 'Lê Văn Tùng',
        dayOfWeek: 2, // Thứ 3
        startTime: '10:15',
        endTime: '12:15',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      ClassSchedule(
        className: 'WEB-K24',
        subject: 'Lập trình Web',
        room: 'C301',
        teacher: 'Lê Văn Tùng',
        dayOfWeek: 5, // Thứ 6
        startTime: '10:15',
        endTime: '12:15',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      ClassSchedule(
        className: 'KT-K24',
        subject: 'Kinh tế học',
        room: 'D401',
        teacher: 'Phạm Thị Hương',
        dayOfWeek: 1, // Thứ 2
        startTime: '08:00',
        endTime: '10:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      ClassSchedule(
        className: 'KT-K24',
        subject: 'Kinh tế học',
        room: 'D401',
        teacher: 'Phạm Thị Hương',
        dayOfWeek: 3, // Thứ 4
        startTime: '08:00',
        endTime: '10:00',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      ClassSchedule(
        className: 'DT-K23',
        subject: 'Vi mạch số',
        room: 'E501',
        teacher: 'Hoàng Văn Nam',
        dayOfWeek: 2, // Thứ 3
        startTime: '13:30',
        endTime: '15:30',
        weekPattern: 'Odd',
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      ClassSchedule(
        className: 'DT-K23',
        subject: 'Vi mạch số',
        room: 'E501',
        teacher: 'Hoàng Văn Nam',
        dayOfWeek: 4, // Thứ 5
        startTime: '13:30',
        endTime: '15:30',
        weekPattern: 'Odd',
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      ClassSchedule(
        className: 'CNTT-K23',
        subject: 'Mạng máy tính',
        room: 'F601',
        teacher: 'Vũ Thị Lan',
        dayOfWeek: 3, // Thứ 4
        startTime: '15:45',
        endTime: '17:45',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 395)),
      ),
      ClassSchedule(
        className: 'CNTT-K23',
        subject: 'Mạng máy tính',
        room: 'F601',
        teacher: 'Vũ Thị Lan',
        dayOfWeek: 5, // Thứ 6
        startTime: '15:45',
        endTime: '17:45',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 395)),
      ),
      ClassSchedule(
        className: 'DOAN-K22',
        subject: 'Đồ án tốt nghiệp',
        room: 'G701',
        teacher: 'Đặng Văn Quang',
        dayOfWeek: 4, // Thứ 5
        startTime: '08:00',
        endTime: '11:00',
        weekPattern: 'Even',
        createdAt: now.subtract(const Duration(days: 750)),
      ),
      ClassSchedule(
        className: 'KT-K24',
        subject: 'Quản trị kinh doanh',
        room: 'H801',
        teacher: 'Bùi Thị Hoa',
        dayOfWeek: 1, // Thứ 2
        startTime: '10:15',
        endTime: '12:15',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      ClassSchedule(
        className: 'KT-K24',
        subject: 'Quản trị kinh doanh',
        room: 'H801',
        teacher: 'Bùi Thị Hoa',
        dayOfWeek: 5, // Thứ 6
        startTime: '10:15',
        endTime: '12:15',
        weekPattern: 'All',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }
}

