import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseDatabaseService._init();

  // Helper to get collection reference
  CollectionReference _collection(String collectionName) => _firestore.collection(collectionName);

  // ========== STUDENT OPERATIONS ==========

  Future<Student> createStudent(Student student) async {
    try {
      final studentsRef = _collection('students');
      final id = DateTime.now().millisecondsSinceEpoch;
      
      final studentMap = student.copyWith(id: id).toMap();
      studentMap['id'] = id;
      
      // Use id as document ID for easier querying
      await studentsRef.doc(id.toString()).set(studentMap);
      
      return student.copyWith(id: id);
    } catch (e) {
      throw 'Tạo sinh viên thất bại: $e';
    }
  }

  Future<Student?> getStudent(int id) async {
    try {
      final doc = await _collection('students').doc(id.toString()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return Student.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final snapshot = await _collection('students').get();
      if (snapshot.docs.isEmpty) return [];
      
      final List<Student> students = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          students.add(Student.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
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
      final snapshot = await _collection('students')
          .where('classCode', isEqualTo: classCode)
          .get();
      
      final List<Student> students = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          students.add(Student.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return students;
    } catch (e) {
      return [];
    }
  }

  Future<Student?> getStudentByStudentId(String studentId) async {
    try {
      final snapshot = await _collection('students')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return Student.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> updateStudent(Student student) async {
    try {
      if (student.id == null) throw 'Student ID is required';
      
      await _collection('students').doc(student.id.toString()).update(student.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật sinh viên thất bại: $e';
    }
  }

  Future<int> deleteStudent(int id) async {
    try {
      await _collection('students').doc(id.toString()).delete();
      
      // Also delete related attendance records
      final recordsSnapshot = await _collection('attendance_records')
          .where('studentId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in recordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return 1;
    } catch (e) {
      throw 'Xóa sinh viên thất bại: $e';
    }
  }

  // ========== SUBJECT OPERATIONS ==========

  Future<Subject> createSubject(Subject subject) async {
    try {
      final subjectsRef = _collection('subjects');
      final id = DateTime.now().millisecondsSinceEpoch;
      
      final subjectMap = subject.copyWith(id: id).toMap();
      subjectMap['id'] = id;
      
      await subjectsRef.doc(id.toString()).set(subjectMap);
      
      return subject.copyWith(id: id);
    } catch (e) {
      throw 'Tạo môn học thất bại: $e';
    }
  }

  Future<Subject?> getSubject(int id) async {
    try {
      final doc = await _collection('subjects').doc(id.toString()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return Subject.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Subject>> getAllSubjects() async {
    try {
      final snapshot = await _collection('subjects').get();
      if (snapshot.docs.isEmpty) return [];
      
      final List<Subject> subjects = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          subjects.add(Subject.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      subjects.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      return subjects;
    } catch (e) {
      return [];
    }
  }

  Future<List<Subject>> getSubjectsByCreator(int creatorId) async {
    try {
      final snapshot = await _collection('subjects')
          .where('creatorId', isEqualTo: creatorId)
          .get();
      
      final List<Subject> subjects = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          subjects.add(Subject.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return subjects;
    } catch (e) {
      return [];
    }
  }

  Future<int> updateSubject(Subject subject) async {
    try {
      if (subject.id == null) throw 'Subject ID is required';
      
      await _collection('subjects').doc(subject.id.toString()).update(subject.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật môn học thất bại: $e';
    }
  }

  Future<int> deleteSubject(int id) async {
    try {
      await _collection('subjects').doc(id.toString()).delete();
      
      // Also delete related sessions
      final sessionsSnapshot = await _collection('attendance_sessions')
          .where('subjectId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return 1;
    } catch (e) {
      throw 'Xóa môn học thất bại: $e';
    }
  }

  // ========== ATTENDANCE SESSION OPERATIONS ==========

  Future<AttendanceSession> createSession(AttendanceSession session) async {
    try {
      final sessionsRef = _collection('attendance_sessions');
      final id = DateTime.now().millisecondsSinceEpoch;
      
      final sessionMap = session.copyWith(id: id).toMap();
      sessionMap['id'] = id;
      
      await sessionsRef.doc(id.toString()).set(sessionMap);
      
      return session.copyWith(id: id);
    } catch (e) {
      throw 'Tạo buổi học thất bại: $e';
    }
  }

  Future<AttendanceSession?> getSession(int id) async {
    try {
      final doc = await _collection('attendance_sessions').doc(id.toString()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return AttendanceSession.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceSession>> getAllSessions() async {
    try {
      final snapshot = await _collection('attendance_sessions')
          .orderBy('createdAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<AttendanceSession> sessions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          sessions.add(AttendanceSession.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceSession>> getSessionsByCreator(int creatorId) async {
    try {
      final snapshot = await _collection('attendance_sessions')
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<AttendanceSession> sessions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          sessions.add(AttendanceSession.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceSession>> getSessionsBySubject(int subjectId) async {
    try {
      final snapshot = await _collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<AttendanceSession> sessions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          sessions.add(AttendanceSession.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<int> updateSession(AttendanceSession session) async {
    try {
      if (session.id == null) throw 'Session ID is required';
      
      final updatedMap = session.toMap();
      updatedMap['updatedAt'] = DateTime.now().toIso8601String();
      await _collection('attendance_sessions').doc(session.id.toString()).update(updatedMap);
      return 1;
    } catch (e) {
      throw 'Cập nhật buổi học thất bại: $e';
    }
  }

  Future<int> deleteSession(int id) async {
    try {
      await _collection('attendance_sessions').doc(id.toString()).delete();
      
      // Also delete related records
      final recordsSnapshot = await _collection('attendance_records')
          .where('sessionId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in recordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return 1;
    } catch (e) {
      throw 'Xóa buổi học thất bại: $e';
    }
  }

  // ========== ATTENDANCE RECORD OPERATIONS ==========

  Future<AttendanceRecord> createRecord(AttendanceRecord record) async {
    try {
      final recordsRef = _collection('attendance_records');
      final id = DateTime.now().millisecondsSinceEpoch;
      
      final recordMap = record.copyWith(id: id).toMap();
      recordMap['id'] = id;
      
      await recordsRef.doc(id.toString()).set(recordMap);
      
      return record.copyWith(id: id);
    } catch (e) {
      throw 'Tạo bản ghi điểm danh thất bại: $e';
    }
  }

  Future<AttendanceRecord?> getRecord(int id) async {
    try {
      final doc = await _collection('attendance_records').doc(id.toString()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return AttendanceRecord.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceRecord>> getRecordsBySession(int sessionId) async {
    try {
      final snapshot = await _collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<AttendanceRecord> records = [];
      for (var doc in snapshot.docs) {
        try {
          final recordMap = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          
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
      
      records.sort((a, b) => (a.studentName ?? '').compareTo(b.studentName ?? ''));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> getRecordsByStudent(int studentId) async {
    try {
      final snapshot = await _collection('attendance_records')
          .where('studentId', isEqualTo: studentId)
          .orderBy('checkInTime', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<AttendanceRecord> records = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          records.add(AttendanceRecord.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<AttendanceRecord?> getRecordBySessionAndStudent(int sessionId, int studentId) async {
    try {
      final snapshot = await _collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return AttendanceRecord.fromMap(data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> updateRecord(AttendanceRecord record) async {
    try {
      if (record.id == null) throw 'Record ID is required';
      
      final updatedMap = record.toMap();
      updatedMap['updatedAt'] = DateTime.now().toIso8601String();
      await _collection('attendance_records').doc(record.id.toString()).update(updatedMap);
      return 1;
    } catch (e) {
      throw 'Cập nhật bản ghi thất bại: $e';
    }
  }

  Future<int> deleteRecord(int id) async {
    try {
      await _collection('attendance_records').doc(id.toString()).delete();
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
      await _collection('users').doc(user.uid).set(user.toMap());
      return user;
    } catch (e) {
      throw 'Tạo người dùng thất bại: $e';
    }
  }

  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return AppUser.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return AppUser.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _collection('users').get();
      if (snapshot.docs.isEmpty) return [];
      
      final List<AppUser> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          users.add(AppUser.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final snapshot = await _collection('users')
          .where('role', isEqualTo: role.name)
          .get();
      
      final List<AppUser> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          users.add(AppUser.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<int> updateUser(AppUser user) async {
    try {
      await _collection('users').doc(user.uid).update(user.toMap());
      return 1;
    } catch (e) {
      throw 'Cập nhật người dùng thất bại: $e';
    }
  }

  Future<int> updateUserLastLogin(String uid) async {
    try {
      await _collection('users').doc(uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
      return 1;
    } catch (e) {
      return 0;
    }
  }

  Future<int> deleteUser(String uid) async {
    try {
      await _collection('users').doc(uid).delete();
      return 1;
    } catch (e) {
      throw 'Xóa người dùng thất bại: $e';
    }
  }

  // ========== QR TOKEN OPERATIONS ==========

  Future<void> createQrToken(Map<String, dynamic> tokenData) async {
    try {
      final tokensRef = _collection('qr_tokens');
      await tokensRef.add(tokenData);
    } catch (e) {
      throw 'Tạo QR token thất bại: $e';
    }
  }

  Future<Map<String, dynamic>?> getQrTokenByToken(String token) async {
    try {
      final snapshot = await _collection('qr_tokens')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return Map<String, dynamic>.from(snapshot.docs.first.data() as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateQrToken(String token, Map<String, dynamic> updates) async {
    try {
      final snapshot = await _collection('qr_tokens')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update(updates);
      }
    } catch (e) {
      throw 'Cập nhật QR token thất bại: $e';
    }
  }

  // ========== QR SCAN HISTORY ==========

  Future<void> addQrScanHistory(Map<String, dynamic> historyData) async {
    try {
      final historyRef = _collection('qr_scan_history');
      await historyRef.add(historyData);
    } catch (e) {
      throw 'Thêm lịch sử quét QR thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getQrScanHistoryByUser(int userId) async {
    try {
      final snapshot = await _collection('qr_scan_history')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        history.add(Map<String, dynamic>.from(doc.data() as Map));
      }
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // ========== SESSION HISTORY ==========

  Future<void> addSessionHistory(Map<String, dynamic> historyData) async {
    try {
      final historyRef = _collection('session_history');
      await historyRef.add(historyData);
    } catch (e) {
      throw 'Thêm lịch sử buổi học thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(int sessionId) async {
    try {
      final snapshot = await _collection('session_history')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        history.add(Map<String, dynamic>.from(doc.data() as Map));
      }
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // ========== EXPORT HISTORY ==========

  Future<void> addExportHistory(Map<String, dynamic> exportData) async {
    try {
      final exportRef = _collection('export_history');
      await exportRef.add(exportData);
    } catch (e) {
      throw 'Thêm lịch sử xuất file thất bại: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getExportHistoryByUser(int userId) async {
    try {
      final snapshot = await _collection('export_history')
          .where('userId', isEqualTo: userId)
          .orderBy('exportedAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        history.add(Map<String, dynamic>.from(doc.data() as Map));
      }
      
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
      final snapshot = await _collection('attendance_sessions')
          .where('sessionCode', isEqualTo: sessionCode)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return AttendanceSession.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get sessions by student class code
  Future<List<AttendanceSession>> getSessionsByStudentClass(String classCode) async {
    try {
      final snapshot = await _collection('attendance_sessions')
          .where('classCode', isEqualTo: classCode)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<AttendanceSession> sessions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          sessions.add(AttendanceSession.fromMap(data));
        } catch (e) {
          // Skip invalid entries
        }
      }
      return sessions;
    } catch (e) {
      return [];
    }
  }

  // Get all QR tokens for a session
  Future<List<Map<String, dynamic>>> getQrTokensBySession(int sessionId) async {
    try {
      final snapshot = await _collection('qr_tokens')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<Map<String, dynamic>> tokens = [];
      for (var doc in snapshot.docs) {
        tokens.add(Map<String, dynamic>.from(doc.data() as Map));
      }
      
      return tokens;
    } catch (e) {
      return [];
    }
  }

  // Delete expired QR tokens
  Future<int> deleteExpiredQrTokens() async {
    try {
      final now = DateTime.now();
      final snapshot = await _collection('qr_tokens')
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();
      
      if (snapshot.docs.isEmpty) return 0;
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get all export history (for admin)
  Future<List<Map<String, dynamic>>> getAllExportHistory() async {
    try {
      final snapshot = await _collection('export_history')
          .orderBy('exportedAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        history.add(Map<String, dynamic>.from(doc.data() as Map));
      }
      
      return history;
    } catch (e) {
      return [];
    }
  }

  // Delete export history entry
  Future<void> deleteExportHistory(int id) async {
    try {
      // In Firestore, we need to find by document ID or use a query
      // Since we don't have direct ID access, we'll need to query and delete
      // For now, we'll skip deletion by ID - this is a limitation of the current structure
      // The caller should use userId-based queries instead
      throw 'Delete by ID not directly supported in Firestore structure';
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
