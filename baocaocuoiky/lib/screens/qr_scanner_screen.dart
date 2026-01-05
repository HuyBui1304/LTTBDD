import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../database/database_helper.dart';
import '../services/qr_service.dart';
import '../services/qr_token_service.dart';
import '../providers/auth_provider.dart';

class QRScannerScreen extends StatefulWidget {
  final AttendanceSession? session;

  const QRScannerScreen({super.key, this.session});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final QRService _qrService = QRService.instance;
  final QrTokenService _qrTokenService = QrTokenService.instance;
  MobileScannerController cameraController = MobileScannerController();
  
  bool _isProcessing = false;
  String? _scannedData;
  bool _showCodeInput = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQRDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData == _scannedData) return;

    setState(() {
      _isProcessing = true;
      _scannedData = qrData;
    });

    // Parse QR data
    final parsedData = _qrService.parseQRData(qrData);

    if (parsedData == null) {
      _showError('Mã QR không hợp lệ');
      setState(() => _isProcessing = false);
      return;
    }

    // Check QR type
    if (parsedData['type'] == 'attendance_token') {
      // New token-based QR
      await _handleTokenQR(parsedData);
    } else if (parsedData['type'] == 'attendance_session') {
      // Legacy: Old session-based QR
      await _handleSessionQR(parsedData);
    } else if (parsedData['type'] == 'student') {
      // Legacy: Support quét QR sinh viên (dùng khi giáo viên quét)
      if (widget.session != null) {
        await _handleStudentQR(parsedData);
      } else {
        _showError('Vui lòng quét mã QR buổi học để điểm danh');
        setState(() => _isProcessing = false);
      }
    } else {
      _showError('Loại mã QR không được hỗ trợ');
      setState(() => _isProcessing = false);
    }
  }

  // Handle token-based QR (new method)
  Future<void> _handleTokenQR(Map<String, dynamic> qrData) async {
    try {
      final token = qrData['token'] as String?;
      final sessionId = qrData['sessionId'] as int?;

      if (token == null || sessionId == null) {
        _showError('Mã QR không hợp lệ');
        setState(() => _isProcessing = false);
        return;
      }

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showError('Vui lòng đăng nhập');
        setState(() => _isProcessing = false);
        return;
      }

      // Get user ID from UID (hash-based for Firebase compatibility)
      final userId = _db.uidToUserId(currentUser.uid);

      // Get student by user email
      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
      );

      // Get session to check subject
      final session = await _db.getSession(sessionId);
      if (session == null) {
        _showError('Không tìm thấy buổi học');
        setState(() => _isProcessing = false);
        return;
      }

      // Validate: Check if student is enrolled in this subject
      final subjectIdStr = session.subjectId.toString();
      final studentSubjectIds = student.subjectIds ?? [];
      if (!studentSubjectIds.contains(subjectIdStr)) {
        // Student is not enrolled in this subject - show generic error message
        _showError('Mã điểm danh không hợp lệ hoặc đã hết hạn');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if already attended FIRST (before validating token)
      final existing = await _db.getRecordBySessionAndStudent(
        sessionId,
        student.id!,
      );

      if (existing != null) {
        _showWarning('Bạn đã điểm danh rồi!');
        setState(() => _isProcessing = false);
        return;
      }

      // Not attended yet - now validate and consume token
      final result = await _qrTokenService.validateAndConsumeToken(
        token: token,
        userId: userId,
      );

      if (!result['valid']) {
        _showError(result['message'] ?? 'Mã QR không hợp lệ');
        setState(() => _isProcessing = false);
        return;
      }

      // Create attendance record
      final record = AttendanceRecord(
        sessionId: sessionId,
        studentId: student.id!,
        status: AttendanceStatus.present,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.qrScan,
        note: 'Điểm danh bằng QR',
      );

      await _db.createRecord(record);

      _showSuccess('Điểm danh thành công!\n${student.name}');
      
      // Reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _scannedData = null;
          });
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _showError('Lỗi: $e');
      setState(() => _isProcessing = false);
    }
  }

  // Handle khi học sinh quét QR buổi học (legacy)
  Future<void> _handleSessionQR(Map<String, dynamic> qrData) async {
    try {
      final sessionId = qrData['sessionId'] as int?;

      if (sessionId == null) {
        _showError('Mã QR không hợp lệ: Thiếu thông tin buổi học');
        setState(() => _isProcessing = false);
        return;
      }

      // Get session info
      final session = await _db.getSession(sessionId);
      if (session == null) {
        _showError('Không tìm thấy buổi học');
        setState(() => _isProcessing = false);
        return;
      }

      // Validate QR code (check expiry)
      if (!_qrService.validateQRCode(qrData)) {
        _showError('Mã QR đã hết hạn');
        setState(() => _isProcessing = false);
        return;
      }

      // Show dialog để nhập mã SV
      if (mounted) {
        _showStudentIdInputDialog(session);
      }
    } catch (e) {
      _showError('Lỗi xử lý: $e');
      setState(() => _isProcessing = false);
    }
  }

  // Dialog để nhập mã SV khi quét QR buổi học
  void _showStudentIdInputDialog(AttendanceSession session) {
    final studentIdController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buổi học: ${session.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Mã sinh viên',
                hintText: 'Nhập mã SV của bạn',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              studentIdController.dispose();
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
                _scannedData = null;
              });
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final studentCode = studentIdController.text.trim();
              studentIdController.dispose();
              Navigator.pop(context);
              
              if (studentCode.isEmpty) {
                _showError('Vui lòng nhập mã sinh viên');
                setState(() => _isProcessing = false);
                return;
              }

              await _markAttendanceByStudentCode(session, studentCode);
            },
            child: const Text('Điểm danh'),
          ),
        ],
      ),
    );
  }

  // Điểm danh theo mã SV
  Future<void> _markAttendanceByStudentCode(AttendanceSession session, String studentCode) async {
    try {
      // Tìm student theo mã SV
      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.studentId.toLowerCase() == studentCode.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy sinh viên với mã: $studentCode'),
      );

      // Validate: Check if student is enrolled in this subject
      final subjectIdStr = session.subjectId.toString();
      final studentSubjectIds = student.subjectIds ?? [];
      if (!studentSubjectIds.contains(subjectIdStr)) {
        // Student is not enrolled in this subject - show generic error message
        _showError('Mã điểm danh không hợp lệ hoặc đã hết hạn');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if already attended
      final existing = await _db.getRecordBySessionAndStudent(
        session.id!,
        student.id!,
      );

      if (existing != null) {
        _showWarning('Sinh viên ${student.name} đã điểm danh rồi!');
        setState(() => _isProcessing = false);
        return;
      }

      // Create attendance record
      final record = AttendanceRecord(
        sessionId: session.id!,
        studentId: student.id!,
        status: AttendanceStatus.present,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.qrScan,
        note: 'Điểm danh bằng QR',
      );

      await _db.createRecord(record);

      // Get current user ID for history
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      int? userId;
      
      if (currentUser != null) {
        userId = _db.uidToUserId(currentUser.uid);
      }

      // Save QR scan history
      await _db.createQRScanHistory({
        'userId': userId ?? 1,
        'sessionId': session.id,
        'qrData': jsonEncode({
          'type': 'attendance_session',
          'sessionId': session.id,
          'studentCode': studentCode,
        }),
        'scanType': 'student_checkin',
        'scannedAt': DateTime.now().toIso8601String(),
        'note': 'Điểm danh thành công: ${student.name} ($studentCode)',
      });

      _showSuccess('Điểm danh thành công!\n${student.name} - $studentCode');
      
      // Reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _scannedData = null;
          });
        }
      });
    } catch (e) {
      _showError('Lỗi: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleStudentQR(Map<String, dynamic> qrData) async {
    try {
      final studentId = qrData['studentId'] as int;
      final studentCode = qrData['studentCode'] as String;

      // Get student info
      final student = await _db.getStudent(studentId);
      if (student == null) {
        _showError('Không tìm thấy sinh viên');
        setState(() => _isProcessing = false);
        return;
      }

      // If no session provided, just show student info
      if (widget.session == null) {
        _showSuccess('Mã QR hợp lệ!\nSinh viên: ${student.name}\nMã SV: $studentCode\nLớp: ${student.classCode ?? "N/A"}');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if student already attended (only if session is provided)
      final existing = await _db.getRecordBySessionAndStudent(
        widget.session!.id!,
        studentId,
      );

      if (existing != null) {
        _showWarning('Sinh viên ${student.name} đã điểm danh rồi!');
        setState(() => _isProcessing = false);
        return;
      }

      // Create attendance record
      final record = AttendanceRecord(
        sessionId: widget.session!.id!,
        studentId: studentId,
        status: AttendanceStatus.present,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.qrScan,
        note: 'Điểm danh bằng QR',
      );

      await _db.createRecord(record);

      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      int? userId;
      
      if (currentUser != null) {
        userId = _db.uidToUserId(currentUser.uid);
      }

      // Save QR scan history
      await _db.createQRScanHistory({
        'userId': userId ?? 1, // Fallback to 1 if user not found
        'sessionId': widget.session!.id,
        'qrData': qrData.toString(),
        'scanType': 'student_attendance',
        'scannedAt': DateTime.now().toIso8601String(),
        'note': 'Điểm danh thành công: ${student.name}',
      });

      _showSuccess('Điểm danh thành công!\n${student.name} - $studentCode');
      
      // Reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _scannedData = null;
          });
        }
      });
    } catch (e) {
      _showError('Lỗi xử lý: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade50,
        icon: Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Thành công'),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _handleQRDetected,
          ),

          // Overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.white,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessing
                        ? 'Đang xử lý...'
                        : widget.session != null
                            ? 'Đưa mã QR sinh viên vào khung hình'
                            : 'Đưa mã QR buổi học vào khung hình',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (widget.session != null)
                    Text(
                      'Buổi học: ${widget.session!.title}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Column(
                      children: [
                    Text(
                          'Quét mã QR hoặc nhập mã 4 số',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _showCodeInput = true);
                          },
                          icon: const Icon(Icons.keyboard, color: Colors.white),
                          label: const Text('Nhập mã 4 số', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Code input dialog
          if (_showCodeInput)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nhập mã 4 số',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0000',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (code) async {
                            if (code.length == 4) {
                              await _handleCodeInput(code);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _showCodeInput = false);
                              },
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                // Get code from text field
                                // This is a simplified version - in real app, use a controller
                                // For now, show dialog to enter code
                                _showCodeInputDialog();
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCodeInputDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã 4 số'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            hintText: '0000',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _showCodeInput = false);
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text;
              if (code.length == 4) {
                Navigator.pop(context);
                setState(() => _showCodeInput = false);
                await _handleCodeInput(code);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleCodeInput(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showError('Vui lòng đăng nhập');
        setState(() => _isProcessing = false);
        return;
      }

      // Get user ID from UID (hash-based for Firebase compatibility)
      final userId = _db.uidToUserId(currentUser.uid);

      // Get student by user email
      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
      );

      // Get session - either from widget or need to find active session
      AttendanceSession? session;
      if (widget.session != null) {
        session = widget.session;
      } else {
        // Find active session for student's class
        final classSessions = await _db.getSessionsByStudentClass(student.classCode ?? '');
        // Find scheduled session
        session = classSessions.firstWhere(
          (s) => s.status == SessionStatus.scheduled,
          orElse: () => throw Exception('Không tìm thấy buổi học chưa diễn ra'),
        );
      }

      final sessionId = session?.id;
      if (sessionId == null || session == null) {
        _showError('Buổi học không hợp lệ');
        setState(() => _isProcessing = false);
        return;
      }

      // Validate: Check if student is enrolled in this subject
      final subjectIdStr = session.subjectId.toString();
      final studentSubjectIds = student.subjectIds ?? [];
      if (!studentSubjectIds.contains(subjectIdStr)) {
        // Student is not enrolled in this subject - show generic error message
        _showError('Mã điểm danh không hợp lệ hoặc đã hết hạn');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if already attended FIRST (before validating token)
      final existing = await _db.getRecordBySessionAndStudent(
        sessionId,
        student.id!,
      );

      if (existing != null) {
        _showWarning('Bạn đã điểm danh rồi!');
        setState(() => _isProcessing = false);
        return;
      }

      // Not attended yet - now validate code
      final result = await _qrTokenService.validateByCode4Digits(
        code4Digits: code,
        sessionId: sessionId, // Pass sessionId for faster lookup
        userId: userId,
      );

      if (!result['valid']) {
        _showError(result['message'] ?? 'Mã không đúng hoặc đã hết hạn');
        setState(() => _isProcessing = false);
        return;
      }

      // Create attendance record
      final record = AttendanceRecord(
        sessionId: sessionId,
        studentId: student.id!,
        status: AttendanceStatus.present,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.qrCode,
        note: 'Điểm danh bằng mã 4 số',
      );

      await _db.createRecord(record);

      _showSuccess('Điểm danh thành công!\n${student.name}');
      
      // Reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _scannedData = null;
          });
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _showError('Lỗi: $e');
      setState(() => _isProcessing = false);
    }
  }
}

// Overlay painter for scanner frame
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanArea = size.width * 0.7;
    final double left = (size.width - scanArea) / 2;
    final double top = (size.height - scanArea) / 2;

    // Draw semi-transparent overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanArea, scanArea),
        const Radius.circular(12),
      ));

    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, scanAreaPath);

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Draw corner lines
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(left + scanArea, top),
        Offset(left + scanArea - cornerLength, top), paint);
    canvas.drawLine(Offset(left + scanArea, top),
        Offset(left + scanArea, top + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanArea),
        Offset(left + cornerLength, top + scanArea), paint);
    canvas.drawLine(Offset(left, top + scanArea),
        Offset(left, top + scanArea - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanArea, top + scanArea),
        Offset(left + scanArea - cornerLength, top + scanArea), paint);
    canvas.drawLine(Offset(left + scanArea, top + scanArea),
        Offset(left + scanArea, top + scanArea - cornerLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

