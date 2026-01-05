import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';

class ExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> exportStudents() async {
    final students = await _dbHelper.getAllStudents();
    
    final List<List<dynamic>> rows = [
      ['Mã SV', 'Họ và tên', 'Email', 'Số điện thoại', 'Ngành', 'Khóa', 'Ngày tạo'],
      ...students.map((student) => [
        student.studentId,
        student.name,
        student.email,
        student.phone,
        student.major,
        student.year,
        student.createdAt.toString().split(' ')[0],
      ]),
    ];

    await _exportToCSV('danh_sach_sinh_vien.csv', rows);
  }

  Future<void> exportClassSchedules() async {
    final schedules = await _dbHelper.getAllClassSchedules();
    
    final days = {0: 'Chủ Nhật', 1: 'Thứ 2', 2: 'Thứ 3', 3: 'Thứ 4', 4: 'Thứ 5', 5: 'Thứ 6', 6: 'Thứ 7'};
    
    final List<List<dynamic>> rows = [
      ['Tên lớp', 'Môn học', 'Thứ', 'Thời gian', 'Phòng', 'Giảng viên', 'Tuần học', 'Ngày tạo'],
      ...schedules.map((schedule) => [
        schedule.className,
        schedule.subject,
        days[schedule.dayOfWeek] ?? schedule.dayOfWeek.toString(),
        '${schedule.startTime} - ${schedule.endTime}',
        schedule.room,
        schedule.teacher,
        schedule.weekPattern,
        schedule.createdAt.toString().split(' ')[0],
      ]),
    ];

    await _exportToCSV('danh_sach_lich_hoc.csv', rows);
  }

  Future<void> exportStatistics(
    int totalStudents,
    int totalSchedules,
    Map<String, int> studentsByMajor,
    Map<String, int> studentsByYear,
    Map<String, int> schedulesByDay,
  ) async {
    final days = {'0': 'Chủ Nhật', '1': 'Thứ 2', '2': 'Thứ 3', '3': 'Thứ 4', '4': 'Thứ 5', '5': 'Thứ 6', '6': 'Thứ 7'};

    final List<List<dynamic>> rows = [
      ['THỐNG KÊ'],
      [],
      ['Tổng số sinh viên', totalStudents],
      ['Tổng số lịch học', totalSchedules],
      [],
      ['SINH VIÊN THEO NGÀNH'],
      ['Ngành', 'Số lượng'],
      ...studentsByMajor.entries.map((e) => [e.key, e.value]),
      [],
      ['SINH VIÊN THEO KHÓA'],
      ['Khóa', 'Số lượng'],
      ...studentsByYear.entries.map((e) => ['Khóa ${e.key}', e.value]),
      [],
      ['LỊCH HỌC THEO THỨ'],
      ['Thứ', 'Số lượng'],
      ...schedulesByDay.entries.map((e) => [
        days[e.key] ?? e.key,
        e.value,
      ]),
    ];

    await _exportToCSV('thong_ke.csv', rows);
  }

  Future<void> exportStudentsPDF({
    DateTime? startDate,
    DateTime? endDate,
    String? majorFilter,
    int? yearFilter,
  }) async {
    List<Student> students = await _dbHelper.getAllStudents();

    // Apply filters
    if (startDate != null || endDate != null) {
      students = students.where((s) {
        final created = s.createdAt;
        if (startDate != null && created.isBefore(startDate)) return false;
        if (endDate != null && created.isAfter(endDate)) return false;
        return true;
      }).toList();
    }
    if (majorFilter != null && majorFilter.isNotEmpty) {
      students = students.where((s) => s.major == majorFilter).toList();
    }
    if (yearFilter != null) {
      students = students.where((s) => s.year == yearFilter).toList();
    }

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'DANH SÁCH SINH VIÊN',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Ngày xuất: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
              ),
              if (startDate != null || endDate != null)
                pw.Text(
                  'Khoảng thời gian: ${startDate != null ? dateFormat.format(startDate) : '...'} - ${endDate != null ? dateFormat.format(endDate) : '...'}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Mã SV', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Họ và tên', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Email', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Ngành', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Khóa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...students.map((student) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(student.studentId, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(student.name, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(student.email, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(student.major, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(student.year.toString(), style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      )),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                'Tổng số: ${students.length} sinh viên',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> exportSchedulesPDF({
    DateTime? startDate,
    DateTime? endDate,
    int? dayFilter,
    String? subjectFilter,
  }) async {
    List<ClassSchedule> schedules = await _dbHelper.getAllClassSchedules();

    // Apply filters
    if (startDate != null || endDate != null) {
      schedules = schedules.where((s) {
        final created = s.createdAt;
        if (startDate != null && created.isBefore(startDate)) return false;
        if (endDate != null && created.isAfter(endDate)) return false;
        return true;
      }).toList();
    }
    if (dayFilter != null) {
      schedules = schedules.where((s) => s.dayOfWeek == dayFilter).toList();
    }
    if (subjectFilter != null && subjectFilter.isNotEmpty) {
      schedules = schedules.where((s) => s.subject == subjectFilter).toList();
    }

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final days = {0: 'Chủ Nhật', 1: 'Thứ 2', 2: 'Thứ 3', 3: 'Thứ 4', 4: 'Thứ 5', 5: 'Thứ 6', 6: 'Thứ 7'};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'DANH SÁCH LỊCH HỌC',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Ngày xuất: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
              ),
              if (startDate != null || endDate != null)
                pw.Text(
                  'Khoảng thời gian: ${startDate != null ? dateFormat.format(startDate) : '...'} - ${endDate != null ? dateFormat.format(endDate) : '...'}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Tên lớp', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Môn học', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Thứ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Thời gian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Phòng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...schedules.map((schedule) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(schedule.className, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(schedule.subject, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(days[schedule.dayOfWeek] ?? schedule.dayOfWeek.toString(), style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('${schedule.startTime} - ${schedule.endTime}', style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(schedule.room, style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      )),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                'Tổng số: ${schedules.length} lịch học',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> exportStatisticsPDF(
    int totalStudents,
    int totalSchedules,
    Map<String, int> studentsByMajor,
    Map<String, int> studentsByYear,
    Map<String, int> schedulesByDay, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final days = {'0': 'Chủ Nhật', '1': 'Thứ 2', '2': 'Thứ 3', '3': 'Thứ 4', '4': 'Thứ 5', '5': 'Thứ 6', '6': 'Thứ 7'};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'BÁO CÁO THỐNG KÊ',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Ngày xuất: ${dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (startDate != null || endDate != null)
              pw.Text(
                'Khoảng thời gian: ${startDate != null ? dateFormat.format(startDate) : '...'} - ${endDate != null ? dateFormat.format(endDate) : '...'}',
                style: pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 20),
            pw.Text(
              'TỔNG QUAN',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Tổng số sinh viên:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      totalStudents.toString(),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Tổng số lịch học:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      totalSchedules.toString(),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            if (studentsByMajor.isNotEmpty) ...[
              pw.Text(
                'SINH VIÊN THEO NGÀNH',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Ngành', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Số lượng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...studentsByMajor.entries.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
            if (studentsByYear.isNotEmpty) ...[
              pw.Text(
                'SINH VIÊN THEO KHÓA',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Khóa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Số lượng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...studentsByYear.entries.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Khóa ${e.key}', style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
            if (schedulesByDay.isNotEmpty) ...[
              pw.Text(
                'LỊCH HỌC THEO THỨ',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Thứ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Số lượng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...schedulesByDay.entries.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(days[e.key] ?? e.key, style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      )),
                ],
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportToCSV(String fileName, List<List<dynamic>> rows) async {
    try {
      final String csv = const ListToCsvConverter().convert(rows);
      final Directory? directory = await getExternalStorageDirectory();
      
      if (directory == null) {
        throw Exception('Không thể truy cập thư mục lưu trữ');
      }

      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      
      await file.writeAsString(csv);

      // Share the file
      final XFile xFile = XFile(filePath);
      await Share.shareXFiles([xFile], text: 'Xuất dữ liệu: $fileName');
    } catch (e) {
      throw Exception('Lỗi khi xuất file CSV: $e');
    }
  }
}

