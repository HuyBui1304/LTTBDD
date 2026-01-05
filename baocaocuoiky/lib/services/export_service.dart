import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/export_history.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  pw.Font? _vietnameseFont;
  bool _fontLoaded = false;

  ExportService._init();

  // Load Vietnamese font from assets
  Future<void> _loadVietnameseFont() async {
    if (_fontLoaded) return;
    
    try {
      // Try to load Noto Sans font from assets
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      _vietnameseFont = pw.Font.ttf(fontData);
      _fontLoaded = true;
    } catch (e) {
      // If font not found, try other common Vietnamese fonts
      try {
        final fontData = await rootBundle.load('assets/fonts/NotoSans-Vietnamese.ttf');
        _vietnameseFont = pw.Font.ttf(fontData);
        _fontLoaded = true;
      } catch (e2) {
        try {
          final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
          _vietnameseFont = pw.Font.ttf(fontData);
          _fontLoaded = true;
        } catch (e3) {
          // Font not available, will use default font
          _fontLoaded = true;
        }
      }
    }
  }

  // Get text style with Vietnamese font
  pw.TextStyle _getTextStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
  }) {
    if (_vietnameseFont != null) {
      return pw.TextStyle(
        font: _vietnameseFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Log export to history
  Future<void> _logExport({
    required int userId,
    required String userName,
    required String exportType,
    required String format,
    required String fileName,
    String? filePath,
  }) async {
    final history = ExportHistory(
      userId: userId,
      userName: userName,
      exportType: exportType,
      format: format,
      fileName: fileName,
      filePath: filePath,
    );
    await _db.createExportHistory(history.toMap());
  }

  // Export students to CSV
  Future<String> exportStudentsToCSV({int? userId, String? userName}) async {
    try {
      final students = await _db.getAllStudents();
      
      final List<List<dynamic>> rows = [
        ['Mã SV', 'Họ tên', 'Email', 'Số điện thoại', 'Mã lớp', 'Ngày tạo'],
      ];

      for (final student in students) {
        rows.add([
          student.studentId,
          student.name,
          student.email,
          student.phone ?? '',
          student.classCode ?? '',
          DateFormat('dd/MM/yyyy HH:mm').format(student.createdAt),
        ]);
      }

      final filePath = await _saveCSV(rows, 'students');
      
      // Log export
      if (userId != null && userName != null) {
        await _logExport(
          userId: userId,
          userName: userName,
          exportType: 'students',
          format: 'csv',
          fileName: filePath.split('/').last,
          filePath: filePath,
        );
      }
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  // Export sessions to CSV
  Future<String> exportSessionsToCSV({int? userId, String? userName}) async {
    try {
      final sessions = await _db.getAllSessions();
      
      final List<List<dynamic>> rows = [
        ['Mã buổi', 'Tiêu đề', 'Mô tả', 'Mã lớp', 'Ngày học', 'Địa điểm', 'Trạng thái', 'Ngày tạo'],
      ];

      for (final session in sessions) {
        rows.add([
          session.sessionCode,
          session.title,
          session.description ?? '',
          session.classCode,
          session.sessionDate != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!)
              : 'Chưa có ngày',
          session.location ?? '',
          _getSessionStatusText(session.status),
          DateFormat('dd/MM/yyyy HH:mm').format(session.createdAt),
        ]);
      }

      final filePath = await _saveCSV(rows, 'sessions');
      
      // Log export
      if (userId != null && userName != null) {
        await _logExport(
          userId: userId,
          userName: userName,
          exportType: 'sessions',
          format: 'csv',
          fileName: filePath.split('/').last,
          filePath: filePath,
        );
      }
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  // Export sessions by subject to CSV
  Future<String> exportSessionsBySubjectToCSV({
    required Subject subject,
    required List<AttendanceSession> sessions,
  }) async {
    try {
      final List<List<dynamic>> rows = [
        ['MÔN HỌC: ${subject.subjectName}'],
        ['Mã môn: ${subject.subjectCode}'],
        ['Lớp: ${subject.classCode}'],
        ['Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'],
        [],
        ['STT', 'Buổi', 'Mã buổi', 'Tiêu đề', 'Mô tả', 'Ngày học', 'Địa điểm', 'Trạng thái'],
      ];

      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        rows.add([
          i + 1,
          session.sessionNumber,
          session.sessionCode,
          session.title,
          session.description ?? '',
          session.sessionDate != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!)
              : 'Chưa có ngày',
          session.location ?? '',
          _getSessionStatusText(session.status),
        ]);
      }

      final filePath = await _saveCSV(rows, 'sessions_${subject.subjectCode}');
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  // Export attendance records to CSV
  Future<String> exportAttendanceToCSV(int sessionId, {int? userId, String? userName}) async {
    try {
      final session = await _db.getSession(sessionId);
      if (session == null) throw Exception('Session not found');

      final records = await _db.getRecordsBySession(sessionId);
      
      final List<List<dynamic>> rows = [
        ['Buổi học: ${session.title} (${session.sessionCode})'],
        ['Ngày: ${session.sessionDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!) : 'Chưa có ngày'}'],
        ['Mã lớp: ${session.classCode}'],
        [],
        ['Mã SV', 'Họ tên', 'Trạng thái', 'Giờ check-in', 'Ghi chú'],
      ];

      for (final record in records) {
        final student = await _db.getStudent(record.studentId);
        rows.add([
          student?.studentId ?? '',
          student?.name ?? '',
          _getAttendanceStatusText(record.status),
          DateFormat('HH:mm:ss').format(record.checkInTime),
          record.note ?? '',
        ]);
      }

      // Add stats
      final stats = await _db.getSessionStats(sessionId);
      rows.addAll([
        [],
        ['THỐNG KÊ'],
        ['Có mặt', stats['present'] ?? 0],
        ['Vắng', stats['absent'] ?? 0],
        ['Muộn', stats['late'] ?? 0],
        ['Có phép', stats['excused'] ?? 0],
      ]);

      final filePath = await _saveCSV(rows, 'attendance_${session.sessionCode}');
      
      // Log export
      if (userId != null && userName != null) {
        await _logExport(
          userId: userId,
          userName: userName,
          exportType: 'attendance',
          format: 'csv',
          fileName: filePath.split('/').last,
          filePath: filePath,
        );
      }
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  // Export all data to CSV (comprehensive report)
  Future<String> exportAllDataToCSV({int? userId, String? userName}) async {
    try {
      final students = await _db.getAllStudents();
      final sessions = await _db.getAllSessions();
      
      final List<List<dynamic>> rows = [
        ['BÁO CÁO TỔNG HỢP ĐIỂM DANH'],
        ['Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'],
        [],
        ['Tổng số sinh viên: ${students.length}'],
        ['Tổng số buổi học: ${sessions.length}'],
        [],
      ];

      for (final session in sessions) {
        final records = await _db.getRecordsBySession(session.id!);
        final stats = await _db.getSessionStats(session.id!);
        
        rows.addAll([
          ['BUỔI HỌC: ${session.title}'],
          ['Mã: ${session.sessionCode}', 'Ngày: ${session.sessionDate != null ? DateFormat('dd/MM/yyyy').format(session.sessionDate!) : 'Chưa có ngày'}', 'Lớp: ${session.classCode}'],
          ['Mã SV', 'Họ tên', 'Trạng thái'],
        ]);

        for (final record in records) {
          final student = await _db.getStudent(record.studentId);
          rows.add([
            student?.studentId ?? '',
            student?.name ?? '',
            _getAttendanceStatusText(record.status),
          ]);
        }

        rows.addAll([
          ['Có mặt: ${stats['present']}', 'Vắng: ${stats['absent']}', 'Muộn: ${stats['late']}', 'Có phép: ${stats['excused']}'],
          [],
        ]);
      }

      final filePath = await _saveCSV(rows, 'full_report');
      
      // Log export
      if (userId != null && userName != null) {
        await _logExport(
          userId: userId,
          userName: userName,
          exportType: 'full_report',
          format: 'csv',
          fileName: filePath.split('/').last,
          filePath: filePath,
        );
      }
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _saveCSV(List<List<dynamic>> rows, String filename) async {
    final String csv = const ListToCsvConverter().convert(rows);
    
    // Thêm UTF-8 BOM để Excel có thể mở được file với tiếng Việt
    final utf8Bom = '\uFEFF';
    final csvWithBom = utf8Bom + csv;
    
    // Lưu vào Downloads thay vì app documents
    Directory? directory;
    if (Platform.isAndroid) {
      // Android: Lưu vào Downloads
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      // iOS: Lưu vào Documents
      directory = await getApplicationDocumentsDirectory();
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory!.path}/${filename}_$timestamp.csv';
    
    final File file = File(path);
    // Ghi file với UTF-8 encoding
    await file.writeAsString(csvWithBom, encoding: const Utf8Codec());
    
    return path;
  }

  String _getSessionStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return 'Chưa diễn ra';
      case SessionStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  String _getAttendanceStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.late:
        return 'Muộn';
      case AttendanceStatus.excused:
        return 'Có phép';
    }
  }

  // ==================== PDF EXPORT ====================

  // Export students to PDF
  Future<String> exportStudentsToPDF() async {
    try {
      await _loadVietnameseFont();
      final students = await _db.getAllStudents();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('DANH SÁCH SINH VIÊN',
                  style: _getTextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: _getTextStyle()),
            pw.Text('Tổng số: ${students.length} sinh viên',
                style: _getTextStyle()),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['STT', 'Mã SV', 'Họ tên', 'Email', 'SĐT', 'Mã lớp'],
              data: students.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final student = entry.value;
                return [
                  idx.toString(),
                  student.studentId,
                  student.name,
                  student.email,
                  student.phone ?? '',
                  student.classCode ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'students');
    } catch (e) {
      rethrow;
    }
  }

  // Export attendance to PDF
  Future<String> exportAttendanceToPDF(int sessionId) async {
    try {
      await _loadVietnameseFont();
      final session = await _db.getSession(sessionId);
      if (session == null) throw Exception('Session not found');

      final records = await _db.getRecordsBySession(sessionId);
      final stats = await _db.getSessionStats(sessionId);
      final tableData = await _buildAttendanceTableData(records);
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BẢNG ĐIỂM DANH',
                      style: _getTextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Buổi học: ${session.title}',
                      style: _getTextStyle(fontSize: 16)),
                  pw.Text('Mã buổi: ${session.sessionCode}',
                      style: _getTextStyle()),
                  pw.Text('Ngày: ${session.sessionDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!) : 'Chưa có ngày'}',
                      style: _getTextStyle()),
                  pw.Text('Lớp: ${session.classCode}',
                      style: _getTextStyle()),
                  if (session.location != null)
                    pw.Text('Địa điểm: ${session.location}',
                        style: _getTextStyle()),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Statistics Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Có mặt', stats['present'] ?? 0, PdfColors.green),
                  _buildStatItem('Vắng', stats['absent'] ?? 0, PdfColors.red),
                  _buildStatItem('Muộn', stats['late'] ?? 0, PdfColors.orange),
                  _buildStatItem('Có phép', stats['excused'] ?? 0, PdfColors.blue),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Attendance Table
            pw.TableHelper.fromTextArray(
              headers: ['STT', 'Mã SV', 'Họ tên', 'Trạng thái', 'Giờ check-in', 'Ghi chú'],
              data: tableData,
              headerStyle: _getTextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: _getTextStyle(),
            ),

            pw.SizedBox(height: 30),
            pw.Text('Ký tên:',
                style: _getTextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 50),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Giảng viên', style: _getTextStyle()),
                    pw.SizedBox(height: 50),
                    pw.Text('(Ký và ghi rõ họ tên)', style: _getTextStyle()),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Sinh viên lớp trưởng', style: _getTextStyle()),
                    pw.SizedBox(height: 50),
                    pw.Text('(Ký và ghi rõ họ tên)', style: _getTextStyle()),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'attendance_${session.sessionCode}');
    } catch (e) {
      rethrow;
    }
  }

  // Export full report to PDF
  Future<String> exportFullReportToPDF() async {
    try {
      await _loadVietnameseFont();
      final students = await _db.getAllStudents();
      final sessions = await _db.getAllSessions();
      
      // Build session widgets ahead of time
      final sessionWidgets = <pw.Widget>[];
      for (final session in sessions) {
        final stats = await _db.getSessionStats(session.id!);
        sessionWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(session.title,
                    style: _getTextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Mã: ${session.sessionCode} | Lớp: ${session.classCode} | Ngày: ${session.sessionDate != null ? DateFormat('dd/MM/yyyy').format(session.sessionDate!) : 'Chưa có ngày'}',
                    style: _getTextStyle()),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Text('Có mặt: ${stats['present']}', style: _getTextStyle(color: PdfColors.green)),
                    pw.SizedBox(width: 15),
                    pw.Text('Vắng: ${stats['absent']}', style: _getTextStyle(color: PdfColors.red)),
                    pw.SizedBox(width: 15),
                    pw.Text('Muộn: ${stats['late']}', style: _getTextStyle(color: PdfColors.orange)),
                    pw.SizedBox(width: 15),
                    pw.Text('Có phép: ${stats['excused']}', style: _getTextStyle(color: PdfColors.blue)),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BÁO CÁO TỔNG HỢP ĐIỂM DANH',
                      style: _getTextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: _getTextStyle()),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Overview
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TỔNG QUAN',
                      style: _getTextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Tổng số sinh viên: ${students.length}',
                      style: _getTextStyle()),
                  pw.Text('Tổng số buổi học: ${sessions.length}',
                      style: _getTextStyle()),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Sessions summary
            pw.Text('CHI TIẾT CÁC BUỔI HỌC',
                style: _getTextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            
            ...sessionWidgets,
          ],
        ),
      );

      return await _savePDF(pdf, 'full_report');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<List<dynamic>>> _buildAttendanceTableData(List<AttendanceRecord> records) async {
    final data = <List<dynamic>>[];
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final student = await _db.getStudent(record.studentId);
      data.add([
        (i + 1).toString(),
        student?.studentId ?? '',
        student?.name ?? '',
        _getAttendanceStatusText(record.status),
        DateFormat('HH:mm:ss').format(record.checkInTime),
        record.note ?? '',
      ]);
    }
    return data;
  }

  pw.Widget _buildStatItem(String label, int value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value.toString(),
            style: _getTextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label, style: _getTextStyle(fontSize: 10)),
      ],
    );
  }

  Future<String> _savePDF(pw.Document pdf, String filename) async {
    // Lưu vào Downloads thay vì app documents
    Directory? directory;
    if (Platform.isAndroid) {
      // Android: Lưu vào Downloads
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      // iOS: Lưu vào Documents
      directory = await getApplicationDocumentsDirectory();
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory!.path}/${filename}_$timestamp.pdf';
    
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  // ========== SHARE METHODS ==========

  /// Share a file (CSV or PDF)
  Future<void> shareFile({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw 'File không tồn tại: $filePath';
      }

      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: text,
      );
    } catch (e) {
      throw 'Chia sẻ thất bại: $e';
    }
  }

  /// Export and share sessions as CSV
  Future<void> exportAndShareSessionsCSV({
    required Subject subject,
    required List<AttendanceSession> sessions,
  }) async {
    try {
      // Export to CSV
      final filePath = await exportSessionsBySubjectToCSV(
        subject: subject,
        sessions: sessions,
      );

      // Share the file
      await shareFile(
        filePath: filePath,
        subject: 'Dữ liệu điểm danh - ${subject.subjectName}',
        text: 'Dữ liệu điểm danh môn ${subject.subjectName} (${sessions.length} buổi học)',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Export sessions by subject to PDF
  Future<String> exportSessionsBySubjectToPDF({
    required Subject subject,
    required List<AttendanceSession> sessions,
  }) async {
    try {
      await _loadVietnameseFont();
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'DANH SÁCH BUỔI HỌC',
                  style: _getTextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Môn học: ${subject.subjectName}',
                  style: _getTextStyle()),
              pw.Text('Mã môn: ${subject.subjectCode}',
                  style: _getTextStyle()),
              pw.Text('Lớp: ${subject.classCode}',
                  style: _getTextStyle()),
              pw.Text('Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: _getTextStyle()),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['STT', 'Buổi', 'Tiêu đề', 'Ngày học', 'Trạng thái'],
                headerStyle: _getTextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: _getTextStyle(),
                data: sessions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final session = entry.value;
                  return [
                    '${i + 1}',
                    'Buổi ${session.sessionNumber}',
                    session.title,
                    session.sessionDate != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!)
                        : 'Chưa có ngày',
                    _getSessionStatusText(session.status),
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      return await _savePDF(pdf, 'sessions_${subject.subjectCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Export and share sessions as PDF
  Future<void> exportAndShareSessionsPDF({
    required Subject subject,
    required List<AttendanceSession> sessions,
  }) async {
    try {
      // Export to PDF
      final filePath = await exportSessionsBySubjectToPDF(
        subject: subject,
        sessions: sessions,
      );

      // Share the file
      await shareFile(
        filePath: filePath,
        subject: 'Báo cáo điểm danh - ${subject.subjectName}',
        text: 'Báo cáo điểm danh môn ${subject.subjectName} (${sessions.length} buổi học)',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create and share time-based report
  Future<void> shareTimeBasedReport({
    required String period, // 'day', 'week', 'month'
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, int> stats,
    required String format, // 'csv' or 'pdf'
  }) async {
    try {
      String filePath;
      
      if (format == 'csv') {
        // Create CSV report
        final List<List<dynamic>> rows = [
          ['Báo cáo theo thời gian'],
          ['Kỳ báo cáo', period == 'day' ? 'Ngày' : period == 'week' ? 'Tuần' : 'Tháng'],
          ['Từ ngày', DateFormat('dd/MM/yyyy').format(startDate)],
          ['Đến ngày', DateFormat('dd/MM/yyyy').format(endDate)],
          [],
          ['Thống kê', 'Số lượng'],
          ['Tổng buổi học', stats['sessions'] ?? 0],
          ['Có mặt', stats['present'] ?? 0],
          ['Vắng mặt', stats['absent'] ?? 0],
          ['Đi muộn', stats['late'] ?? 0],
          ['Có phép', stats['excused'] ?? 0],
        ];

        filePath = await _saveCSV(rows, 'report_$period');
      } else {
        // Create PDF report
        final pdf = pw.Document();
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BÁO CÁO ĐIỂM DANH THEO THỜI GIAN',
                    style: _getTextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Kỳ báo cáo: ${period == 'day' ? 'Ngày' : period == 'week' ? 'Tuần' : 'Tháng'}',
                      style: _getTextStyle()),
                  pw.Text('Từ ngày: ${DateFormat('dd/MM/yyyy').format(startDate)}',
                      style: _getTextStyle()),
                  pw.Text('Đến ngày: ${DateFormat('dd/MM/yyyy').format(endDate)}',
                      style: _getTextStyle()),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text('THỐNG KÊ:', style: _getTextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Tổng buổi học: ${stats['sessions'] ?? 0}',
                      style: _getTextStyle()),
                  pw.Text('Có mặt: ${stats['present'] ?? 0}',
                      style: _getTextStyle()),
                  pw.Text('Vắng mặt: ${stats['absent'] ?? 0}',
                      style: _getTextStyle()),
                  pw.Text('Đi muộn: ${stats['late'] ?? 0}',
                      style: _getTextStyle()),
                  pw.Text('Có phép: ${stats['excused'] ?? 0}',
                      style: _getTextStyle()),
                ],
              );
            },
          ),
        );

        filePath = await _savePDF(pdf, 'report_$period');
      }

      // Share the file
      await shareFile(
        filePath: filePath,
        subject: 'Báo cáo điểm danh theo ${period == 'day' ? 'ngày' : period == 'week' ? 'tuần' : 'tháng'}',
        text: 'Báo cáo điểm danh từ ${DateFormat('dd/MM/yyyy').format(startDate)} đến ${DateFormat('dd/MM/yyyy').format(endDate)}',
      );
    } catch (e) {
      throw 'Chia sẻ báo cáo thất bại: $e';
    }
  }
}

