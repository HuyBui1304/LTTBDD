import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import '../models/student.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import 'package:crypto/crypto.dart' show sha256;

class Crypto {
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

class FirebaseDatabaseService {
  static final FirebaseDatabaseService instance = FirebaseDatabaseService._init();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  FirebaseDatabaseService._init();

  // Helper to get reference for a path
  DatabaseReference _ref(String path) => _database.child(path);

  // ========== STUDENT OPERATIONS ==========

  Future<Student> createStudent(Student student) async {
    try {
      final studentsRef = _ref('students');
      final newStudentRef = studentsRef.push();
      final id = int.tryParse(newStudentRef.key ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
      
      final studentMap = student.copyWith(id: id).toMap();
      studentMap['id'] = id; // Ensure ID is included
      await newStudentRef.set(studentMap);
      
      return student.copyWith(id: id);
    } catch (e) {
      throw 'Tạo sinh viên thất bại: $e';
    }
  }

  Future<Student?> getStudent(int id) async {
    try {
      final snapshot = await _ref('students').orderByChild('id').equalTo(id).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return Student.fromMap(Map<String, dynamic>.from(entry.value as Map)..['id'] = entry.value['id']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final snapshot = await _ref('students').once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Student> students = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            final studentMap = Map<String, dynamic>.from(value as Map);
            students.add(Student.fromMap(studentMap));
          } catch (e) {
            // Skip invalid entries
          }
        });
      }
      
      students.sort((a, b) => a.name.compareTo(b.name));
      return students;
    } catch (e) {
      return [];
    }
  }

  Future<List<Student>> searchStudents(String query) async {
    try {
      final allStudents = await getAllStudents();
      final lowerQuery = query.toLowerCase();
      return allStudents.where((student) {
        return student.name.toLowerCase().contains(lowerQuery) ||
               student.studentId.toLowerCase().contains(lowerQuery) ||
               student.email.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Student>> getStudentsByClass(String classCode) async {
    try {
      final allStudents = await getAllStudents();
      return allStudents.where((s) => s.classCode == classCode).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Student?> getStudentByStudentId(String studentId) async {
    try {
      final snapshot = await _ref('students').orderByChild('studentId').equalTo(studentId).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return Student.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> updateStudent(Student student) async {
    try {
      if (student.id == null) throw 'Student ID is required';
      
      final snapshot = await _ref('students').orderByChild('id').equalTo(student.id).once();
      if (!snapshot.snapshot.exists) throw 'Student not found';
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('students/$key').update(student.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật sinh viên thất bại: $e';
    }
  }

  Future<int> deleteStudent(int id) async {
    try {
      final snapshot = await _ref('students').orderByChild('id').equalTo(id).once();
      if (!snapshot.snapshot.exists) return 0;
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('students/$key').remove();
      
      // Also delete related attendance records
      final recordsSnapshot = await _ref('attendance_records').orderByChild('studentId').equalTo(id).once();
      if (recordsSnapshot.snapshot.exists && recordsSnapshot.snapshot.value != null) {
        final recordsData = recordsSnapshot.snapshot.value as Map;
        for (final key in recordsData.keys) {
          await _ref('attendance_records/$key').remove();
        }
      }
      
      return 1;
    } catch (e) {
      throw 'Xóa sinh viên thất bại: $e';
    }
  }

  // ========== SUBJECT OPERATIONS ==========

  Future<Subject> createSubject(Subject subject) async {
    try {
      final subjectsRef = _ref('subjects');
      final newSubjectRef = subjectsRef.push();
      final id = int.tryParse(newSubjectRef.key ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
      
      final subjectMap = subject.copyWith(id: id).toMap();
      subjectMap['id'] = id;
      await newSubjectRef.set(subjectMap);
      
      return subject.copyWith(id: id);
    } catch (e) {
      throw 'Tạo môn học thất bại: $e';
    }
  }

  Future<Subject?> getSubject(int id) async {
    try {
      final snapshot = await _ref('subjects').orderByChild('id').equalTo(id).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return Subject.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Subject>> getAllSubjects() async {
    try {
      final snapshot = await _ref('subjects').once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Subject> subjects = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            final subjectMap = Map<String, dynamic>.from(value as Map);
            subjects.add(Subject.fromMap(subjectMap));
          } catch (e) {
            // Skip invalid entries
          }
        });
      }
      
      subjects.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      return subjects;
    } catch (e) {
      return [];
    }
  }

  Future<List<Subject>> getSubjectsByCreator(int creatorId) async {
    try {
      final allSubjects = await getAllSubjects();
      return allSubjects.where((s) => s.creatorId == creatorId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateSubject(Subject subject) async {
    try {
      if (subject.id == null) throw 'Subject ID is required';
      
      final snapshot = await _ref('subjects').orderByChild('id').equalTo(subject.id).once();
      if (!snapshot.snapshot.exists) throw 'Subject not found';
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('subjects/$key').update(subject.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật môn học thất bại: $e';
    }
  }

  Future<int> deleteSubject(int id) async {
    try {
      final snapshot = await _ref('subjects').orderByChild('id').equalTo(id).once();
      if (!snapshot.snapshot.exists) return 0;
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('subjects/$key').remove();
      
      // Also delete related sessions
      final sessionsSnapshot = await _ref('attendance_sessions').orderByChild('subjectId').equalTo(id).once();
      if (sessionsSnapshot.snapshot.exists && sessionsSnapshot.snapshot.value != null) {
        final sessionsData = sessionsSnapshot.snapshot.value as Map;
        for (final sessionKey in sessionsData.keys) {
          await _ref('attendance_sessions/$sessionKey').remove();
        }
      }
      
      return 1;
    } catch (e) {
      throw 'Xóa môn học thất bại: $e';
    }
  }

  // ========== ATTENDANCE SESSION OPERATIONS ==========

  Future<AttendanceSession> createSession(AttendanceSession session) async {
    try {
      final sessionsRef = _ref('attendance_sessions');
      final newSessionRef = sessionsRef.push();
      final id = int.tryParse(newSessionRef.key ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
      
      final sessionMap = session.copyWith(id: id).toMap();
      sessionMap['id'] = id;
      await newSessionRef.set(sessionMap);
      
      return session.copyWith(id: id);
    } catch (e) {
      throw 'Tạo buổi học thất bại: $e';
    }
  }

  Future<AttendanceSession?> getSession(int id) async {
    try {
      final snapshot = await _ref('attendance_sessions').orderByChild('id').equalTo(id).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return AttendanceSession.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceSession>> getAllSessions() async {
    try {
      final snapshot = await _ref('attendance_sessions').once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<AttendanceSession> sessions = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            final sessionMap = Map<String, dynamic>.from(value as Map);
            sessions.add(AttendanceSession.fromMap(sessionMap));
          } catch (e) {
            // Skip invalid entries
          }
        });
      }
      
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceSession>> getSessionsByCreator(int creatorId) async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.where((s) => s.creatorId == creatorId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceSession>> getSessionsBySubject(int subjectId) async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.where((s) => s.subjectId == subjectId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateSession(AttendanceSession session) async {
    try {
      if (session.id == null) throw 'Session ID is required';
      
      final snapshot = await _ref('attendance_sessions').orderByChild('id').equalTo(session.id).once();
      if (!snapshot.snapshot.exists) throw 'Session not found';
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      final updatedMap = session.toMap();
      updatedMap['updatedAt'] = DateTime.now().toIso8601String();
      await _ref('attendance_sessions/$key').update(updatedMap);
      return 1;
    } catch (e) {
      throw 'Cập nhật buổi học thất bại: $e';
    }
  }

  Future<int> deleteSession(int id) async {
    try {
      final snapshot = await _ref('attendance_sessions').orderByChild('id').equalTo(id).once();
      if (!snapshot.snapshot.exists) return 0;
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('attendance_sessions/$key').remove();
      
      // Also delete related records
      final recordsSnapshot = await _ref('attendance_records').orderByChild('sessionId').equalTo(id).once();
      if (recordsSnapshot.snapshot.exists && recordsSnapshot.snapshot.value != null) {
        final recordsData = recordsSnapshot.snapshot.value as Map;
        for (final recordKey in recordsData.keys) {
          await _ref('attendance_records/$recordKey').remove();
        }
      }
      
      return 1;
    } catch (e) {
      throw 'Xóa buổi học thất bại: $e';
    }
  }

  // ========== ATTENDANCE RECORD OPERATIONS ==========

  Future<AttendanceRecord> createRecord(AttendanceRecord record) async {
    try {
      final recordsRef = _ref('attendance_records');
      final newRecordRef = recordsRef.push();
      final id = int.tryParse(newRecordRef.key ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
      
      final recordMap = record.copyWith(id: id).toMap();
      recordMap['id'] = id;
      await newRecordRef.set(recordMap);
      
      return record.copyWith(id: id);
    } catch (e) {
      throw 'Tạo bản ghi điểm danh thất bại: $e';
    }
  }

  Future<AttendanceRecord?> getRecord(int id) async {
    try {
      final snapshot = await _ref('attendance_records').orderByChild('id').equalTo(id).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return AttendanceRecord.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceRecord>> getRecordsBySession(int sessionId) async {
    try {
      final snapshot = await _ref('attendance_records').orderByChild('sessionId').equalTo(sessionId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<AttendanceRecord> records = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        for (final entry in data.entries) {
          try {
            final recordMap = Map<String, dynamic>.from(entry.value as Map);
            
            // Get student info
            if (recordMap['studentId'] != null) {
              final student = await getStudent(recordMap['studentId'] as int);
              if (student != null) {
                recordMap['studentName'] = student.name;
                recordMap['studentCode'] = student.studentId;
              }
            }
            
            // Get teacher info if exists
            if (recordMap['checkedByTeacherId'] != null) {
              final teacher = await getUserByUid(recordMap['checkedByTeacherId'].toString());
              if (teacher != null) {
                recordMap['teacherName'] = teacher.displayName;
              }
            }
            
            records.add(AttendanceRecord.fromMap(recordMap));
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
      
      records.sort((a, b) => (a.studentName ?? '').compareTo(b.studentName ?? ''));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> getRecordsByStudent(int studentId) async {
    try {
      final snapshot = await _ref('attendance_records').orderByChild('studentId').equalTo(studentId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<AttendanceRecord> records = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            records.add(AttendanceRecord.fromMap(Map<String, dynamic>.from(value as Map)));
          } catch (e) {
            // Skip invalid entries
          }
        });
      }
      
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<AttendanceRecord?> getRecordBySessionAndStudent(int sessionId, int studentId) async {
    try {
      final snapshot = await _ref('attendance_records')
          .orderByChild('sessionId')
          .equalTo(sessionId)
          .once();
      
      if (!snapshot.snapshot.exists) return null;
      
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        for (final entry in data.entries) {
          final recordMap = Map<String, dynamic>.from(entry.value as Map);
          if (recordMap['studentId'] == studentId) {
            return AttendanceRecord.fromMap(recordMap);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> updateRecord(AttendanceRecord record) async {
    try {
      if (record.id == null) throw 'Record ID is required';
      
      final snapshot = await _ref('attendance_records').orderByChild('id').equalTo(record.id).once();
      if (!snapshot.snapshot.exists) throw 'Record not found';
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      final updatedMap = record.toMap();
      updatedMap['updatedAt'] = DateTime.now().toIso8601String();
      await _ref('attendance_records/$key').update(updatedMap);
      return 1;
    } catch (e) {
      throw 'Cập nhật bản ghi thất bại: $e';
    }
  }

  Future<int> deleteRecord(int id) async {
    try {
      final snapshot = await _ref('attendance_records').orderByChild('id').equalTo(id).once();
      if (!snapshot.snapshot.exists) return 0;
      
      final data = snapshot.snapshot.value as Map;
      final key = data.keys.first;
      await _ref('attendance_records/$key').remove();
      return 1;
    } catch (e) {
      throw 'Xóa bản ghi thất bại: $e';
    }
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getSessionStats(int sessionId) async {
    try {
      final records = await getRecordsBySession(sessionId);
      final stats = <String, int>{
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };
      
      for (final record in records) {
        final status = record.status.name;
        stats[status] = (stats[status] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getStudentStats(int studentId) async {
    try {
      final records = await getRecordsByStudent(studentId);
      return {
        'totalSessions': records.length,
        'present': records.where((r) => r.status.name == 'present').length,
        'absent': records.where((r) => r.status.name == 'absent').length,
        'late': records.where((r) => r.status.name == 'late').length,
        'excused': records.where((r) => r.status.name == 'excused').length,
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };
    }
  }

  // ========== USER OPERATIONS ==========

  Future<AppUser> createUser(AppUser user) async {
    try {
      final usersRef = _ref('users');
      await usersRef.child(user.uid).set(user.toMap());
      return user;
    } catch (e) {
      throw 'Tạo người dùng thất bại: $e';
    }
  }

  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final snapshot = await _ref('users/$uid').once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        return AppUser.fromMap(Map<String, dynamic>.from(snapshot.snapshot.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _ref('users').orderByChild('email').equalTo(email).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final entry = data.entries.first;
        return AppUser.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _ref('users').once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<AppUser> users = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            users.add(AppUser.fromMap(Map<String, dynamic>.from(value as Map)));
          } catch (e) {
            // Skip invalid entries
          }
        });
      }
      
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((u) => u.role == role).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateUser(AppUser user) async {
    try {
      await _ref('users/${user.uid}').update(user.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật người dùng thất bại: $e';
    }
  }

  Future<int> updateUserLastLogin(String uid) async {
    try {
      await _ref('users/$uid').update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
      return 1;
    } catch (e) {
      return 0;
    }
  }

  Future<int> deleteUser(String uid) async {
    try {
      await _ref('users/$uid').remove();
      return 1;
    } catch (e) {
      throw 'Xóa người dùng thất bại: $e';
    }
  }

  // ========== QR TOKEN OPERATIONS ==========

  Future<void> createQrToken(Map<String, dynamic> tokenData) async {
    try {
      final tokensRef = _ref('qr_tokens');
      await tokensRef.push().set(tokenData);
    } catch (e) {
      throw 'Tạo QR token thất bại: $e';
    }
  }

  Future<Map<String, dynamic>?> getQrTokenByToken(String token) async {
    try {
      final snapshot = await _ref('qr_tokens').orderByChild('token').equalTo(token).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        return Map<String, dynamic>.from(data.values.first as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateQrToken(String token, Map<String, dynamic> updates) async {
    try {
      final snapshot = await _ref('qr_tokens').orderByChild('token').equalTo(token).once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final key = data.keys.first;
        await _ref('qr_tokens/$key').update(updates);
      }
    } catch (e) {
      throw 'Cập nhật QR token thất bại: $e';
    }
  }

  // ========== QR SCAN HISTORY ==========

  Future<void> addQrScanHistory(Map<String, dynamic> historyData) async {
    try {
      final historyRef = _ref('qr_scan_history');
      await historyRef.push().set(historyData);
    } catch (e) {
      throw 'Thêm lịch sử quét QR thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getQrScanHistoryByUser(int userId) async {
    try {
      final snapshot = await _ref('qr_scan_history').orderByChild('userId').equalTo(userId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Map<String, dynamic>> history = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          history.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      history.sort((a, b) {
        final aTime = DateTime.parse(a['scannedAt'] as String);
        final bTime = DateTime.parse(b['scannedAt'] as String);
        return bTime.compareTo(aTime);
      });
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // ========== SESSION HISTORY ==========

  Future<void> addSessionHistory(Map<String, dynamic> historyData) async {
    try {
      final historyRef = _ref('session_history');
      await historyRef.push().set(historyData);
    } catch (e) {
      throw 'Thêm lịch sử buổi học thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(int sessionId) async {
    try {
      final snapshot = await _ref('session_history').orderByChild('sessionId').equalTo(sessionId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Map<String, dynamic>> history = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          history.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      history.sort((a, b) {
        final aTime = DateTime.parse(a['createdAt'] as String);
        final bTime = DateTime.parse(b['createdAt'] as String);
        return bTime.compareTo(aTime);
      });
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // ========== EXPORT HISTORY ==========

  Future<void> addExportHistory(Map<String, dynamic> exportData) async {
    try {
      final exportRef = _ref('export_history');
      await exportRef.push().set(exportData);
    } catch (e) {
      throw 'Thêm lịch sử xuất file thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getExportHistoryByUser(int userId) async {
    try {
      final snapshot = await _ref('export_history').orderByChild('userId').equalTo(userId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Map<String, dynamic>> history = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          history.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      history.sort((a, b) {
        final aTime = DateTime.parse(a['exportedAt'] as String);
        final bTime = DateTime.parse(b['exportedAt'] as String);
        return bTime.compareTo(aTime);
      });
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // Helper method to get user ID from UID (for backward compatibility)
  Future<int?> getUserId(String uid) async {
    // For Firebase, we use UID directly as identifier
    // This method is kept for backward compatibility but returns null
    // Callers should use UID directly instead of numeric ID
    return null;
  }

  // ========== ADDITIONAL METHODS ==========

  // Get session by sessionCode (4-digit code)
  Future<AttendanceSession?> getSessionByCode(String sessionCode) async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.firstWhere(
        (s) => s.sessionCode == sessionCode,
        orElse: () => throw StateError('Session not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Get sessions by student class code
  Future<List<AttendanceSession>> getSessionsByStudentClass(String classCode) async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.where((s) => s.classCode == classCode).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all QR tokens for a session
  Future<List<Map<String, dynamic>>> getQrTokensBySession(int sessionId) async {
    try {
      final snapshot = await _ref('qr_tokens').orderByChild('sessionId').equalTo(sessionId).once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Map<String, dynamic>> tokens = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          tokens.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      return tokens;
    } catch (e) {
      return [];
    }
  }

  // Delete expired QR tokens
  Future<int> deleteExpiredQrTokens() async {
    try {
      final snapshot = await _ref('qr_tokens').once();
      if (!snapshot.snapshot.exists) return 0;
      
      int deletedCount = 0;
      final now = DateTime.now();
      
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        for (final entry in data.entries) {
          try {
            final tokenMap = Map<String, dynamic>.from(entry.value as Map);
            final expiresAt = DateTime.parse(tokenMap['expiresAt'] as String);
            
            if (expiresAt.isBefore(now)) {
              await _ref('qr_tokens/${entry.key}').remove();
              deletedCount++;
            }
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  // Get all export history (for admin)
  Future<List<Map<String, dynamic>>> getAllExportHistory() async {
    try {
      final snapshot = await _ref('export_history').once();
      if (!snapshot.snapshot.exists) return [];
      
      final List<Map<String, dynamic>> history = [];
      if (snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;
        data.forEach((key, value) {
          history.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      history.sort((a, b) {
        final aTime = DateTime.parse(a['exportedAt'] as String);
        final bTime = DateTime.parse(b['exportedAt'] as String);
        return bTime.compareTo(aTime);
      });
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // Delete export history entry
  Future<void> deleteExportHistory(int id) async {
    try {
      // In Firebase, we need to find by userId and exportedAt timestamp
      // Since we don't have direct ID access, we'll need to query and delete
      // For now, we'll skip deletion by ID - this is a limitation of the current structure
      // The caller should use userId-based queries instead
      throw 'Delete by ID not directly supported in Firebase structure';
    } catch (e) {
      throw 'Xóa lịch sử xuất file thất bại: $e';
    }
  }

  // Create session history (alias for addSessionHistory for backward compatibility)
  Future<void> createSessionHistory(Map<String, dynamic> historyData) async {
    return addSessionHistory(historyData);
  }

  // Create QR scan history (alias for addQrScanHistory for backward compatibility)
  Future<void> createQRScanHistory(Map<String, dynamic> historyData) async {
    return addQrScanHistory(historyData);
  }

  // Create export history (alias for addExportHistory for backward compatibility)
  Future<void> createExportHistory(Map<String, dynamic> exportData) async {
    return addExportHistory(exportData);
  }

  // Export all data (for backup/sync)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final students = await getAllStudents();
      final subjects = await getAllSubjects();
      final sessions = await getAllSessions();
      final records = <AttendanceRecord>[];
      
      // Get all records
      for (final session in sessions) {
        if (session.id != null) {
          final sessionRecords = await getRecordsBySession(session.id!);
          records.addAll(sessionRecords);
        }
      }
      
      final users = await getAllUsers();
      
      return {
        'students': students.map((s) => s.toMap()).toList(),
        'subjects': subjects.map((s) => s.toMap()).toList(),
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
        'users': users.map((u) => u.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw 'Xuất dữ liệu thất bại: $e';
    }
  }
}

