import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_record.dart';
import '../models/qr_token.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../services/qr_token_service.dart';
import 'qr_scanner_screen.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final QrTokenService _qrTokenService = QrTokenService.instance;
  final TextEditingController _codeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _markAttendance(String code) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Get current user
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('Chưa đăng nhập');
      }

      // Get user ID from UID (hash-based for Firebase compatibility)
      final userId = _db.uidToUserId(currentUser.uid);

      // Get student by user email
      final allStudents = await _db.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.email.toLowerCase() == currentUser.email.toLowerCase(),
        orElse: () => throw Exception('Không tìm thấy thông tin học sinh'),
      );

      if (student.id == null) {
        throw Exception('Thông tin học sinh không hợp lệ');
      }

      // First, find token by code4Digits to get sessionId (without validating)
      final tokenMap = await _db.findQrTokenByCode4Digits(code);
      
      if (tokenMap == null) {
        // Token not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã điểm danh không hợp lệ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Get sessionId from token
      final qrToken = QrToken.fromMap(tokenMap);
      final sessionId = qrToken.sessionId;

      // Get session to check subject
      final session = await _db.getSession(sessionId);
      if (session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy buổi học'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Validate: Check if student is enrolled in this subject
      final subjectIdStr = session.subjectId.toString();
      final studentSubjectIds = student.subjectIds ?? [];
      if (!studentSubjectIds.contains(subjectIdStr)) {
        // Student is not enrolled in this subject - show generic error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã điểm danh không hợp lệ hoặc đã hết hạn'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Check if already attended FIRST (before validating token)
      final existingRecord = await _db.getRecordBySessionAndStudent(
        sessionId,
        student.id!,
      );

      if (existingRecord != null) {
        // Already attended - return early with proper message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn đã điểm danh cho buổi học này rồi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Not attended yet - now validate and consume token
      final result = await _qrTokenService.validateByCode4Digits(
        code4Digits: code,
        userId: userId,
      );

      if (result['valid'] != true) {
        // Token validation failed (expired or already used)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Mã điểm danh không hợp lệ hoặc đã hết hạn'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Token is valid and consumed, create attendance record
      final record = AttendanceRecord(
        sessionId: sessionId,
        studentId: student.id!,
        status: AttendanceStatus.present,
        checkInTime: DateTime.now(),
        checkInMethod: CheckInMethod.qrCode,
        note: 'Điểm danh bằng mã 4 số',
      );

      await _db.createRecord(record);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Điểm danh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _codeController.clear();
        Navigator.pop(context);
      }
      setState(() => _isProcessing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Điểm danh',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập mã 4 số hoặc quét QR để điểm danh',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Input code section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhập mã điểm danh',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: '0000',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      onSubmitted: (value) {
                        if (value.length == 4) {
                          _markAttendance(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessing || _codeController.text.length != 4
                            ? null
                            : () => _markAttendance(_codeController.text),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isProcessing ? 'Đang xử lý...' : 'Xác nhận'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // OR divider
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'HOẶC',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
              ],
            ),

            const SizedBox(height: 24),

            // QR Scanner button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRScannerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét mã QR'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

