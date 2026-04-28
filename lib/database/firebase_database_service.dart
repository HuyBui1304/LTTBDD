import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import '../models/student.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../models/notification.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:cloud_firestore/cloud_firestore.dart' show Query, GetOptions, Source;

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

  Future<Student?> getStudentByEmail(String email) async {
    try {
      final snapshot = await _collection('students')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return Student.fromMap(data);
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
          // Set id from document ID if not present in data
          final subjectId = data['id'] as int? ?? int.tryParse(doc.id);
          if (subjectId != null) {
            data['id'] = subjectId;
          }
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

  Future<List<Subject>> getSubjectsByCreator(String creatorId) async {
    try {
      final snapshot = await _collection('subjects')
          .where('creatorId', isEqualTo: creatorId)
          .get();
      
      final List<Subject> subjects = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Set id from document ID if not present in data
          final subjectId = data['id'] as int? ?? int.tryParse(doc.id);
          if (subjectId != null) {
            data['id'] = subjectId;
          }
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
      // Get all related sessions first
      final sessionsSnapshot = await _collection('attendance_sessions')
          .where('subjectId', isEqualTo: id)
          .get();
      
      // Delete all attendance records for these sessions
      final batch = _firestore.batch();
      
      // Collect all session IDs and delete sessions in batch
      for (var sessionDoc in sessionsSnapshot.docs) {
        // Add session to batch for deletion
        batch.delete(sessionDoc.reference);
        
        // Get session ID to find related records
        final sessionData = sessionDoc.data() as Map<String, dynamic>?;
        final sessionId = sessionData?['id'] as int?;
        
        if (sessionId != null) {
          // Query and add attendance records to batch
          final recordsSnapshot = await _collection('attendance_records')
              .where('sessionId', isEqualTo: sessionId)
              .get();
          
          for (var recordDoc in recordsSnapshot.docs) {
            batch.delete(recordDoc.reference);
          }
        }
      }
      
      // Commit batch (sessions and records)
      await batch.commit();
      
      // Finally, delete the subject itself
      await _collection('subjects').doc(id.toString()).delete();
      
      debugPrint('✅ [deleteSubject] Successfully deleted subject $id and all related data');
      return 1;
    } catch (e) {
      debugPrint('❌ [deleteSubject] Error deleting subject $id: $e');
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

  Future<List<AttendanceSession>> getSessionsByCreator(String creatorId) async {
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
      // Query without orderBy to avoid composite index requirement
      // Use Source.server to force fetch from server instead of cache
      final snapshot = await _collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .get(const GetOptions(source: Source.server));
      
      debugPrint('🔍 [getSessionsBySubject] Query for subjectId=$subjectId returned ${snapshot.docs.length} documents');
      
      final List<AttendanceSession> sessions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final session = AttendanceSession.fromMap(data);
          debugPrint('  - Session ID: ${doc.id}, sessionNumber: ${session.sessionNumber}, title: ${session.title}');
          sessions.add(session);
        } catch (e) {
          // Skip invalid entries
          debugPrint('Error parsing session ${doc.id}: $e');
        }
      }
      
      // Sort by sessionNumber after fetching
      sessions.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
      
      debugPrint('✅ [getSessionsBySubject] Returning ${sessions.length} sessions for subjectId=$subjectId');
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting sessions by subject: $e');
      // Fallback to cache if server fails
      try {
        final snapshot = await _collection('attendance_sessions')
            .where('subjectId', isEqualTo: subjectId)
            .get();
        
        final List<AttendanceSession> sessions = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            sessions.add(AttendanceSession.fromMap(data));
          } catch (e) {
            debugPrint('Error parsing session ${doc.id}: $e');
          }
        }
        sessions.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
        return sessions;
      } catch (fallbackError) {
        debugPrint('Fallback also failed: $fallbackError');
        return [];
      }
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
      // Get all related attendance records first
      final recordsSnapshot = await _collection('attendance_records')
          .where('sessionId', isEqualTo: id)
          .get();
      
      // Delete records in batch
      final batch = _firestore.batch();
      for (var doc in recordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Finally, delete the session itself
      await _collection('attendance_sessions').doc(id.toString()).delete();
      
      debugPrint('✅ [deleteSession] Successfully deleted session $id and ${recordsSnapshot.docs.length} attendance records');
      return 1;
    } catch (e) {
      debugPrint('❌ [deleteSession] Error deleting session $id: $e');
      throw 'Xóa buổi học thất bại: $e';
    }
  }

  // ========== ATTENDANCE RECORD OPERATIONS ==========

  Future<AttendanceRecord> createRecord(AttendanceRecord record) async {
    return await _withRetry(() async {
      final recordsRef = _collection('attendance_records');
      final id = DateTime.now().millisecondsSinceEpoch;
      
      final recordMap = record.copyWith(id: id).toMap();
      recordMap['id'] = id;
      
      await recordsRef.doc(id.toString()).set(recordMap);
      
      return record.copyWith(id: id);
    }, errorMessage: 'Tạo bản ghi điểm danh thất bại');
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
    return await _withRetry(() async {
      if (record.id == null) throw 'Record ID is required';
      
      final updatedMap = record.toMap();
      updatedMap['updatedAt'] = DateTime.now().toIso8601String();
      await _collection('attendance_records').doc(record.id.toString()).update(updatedMap);
      return 1;
    }, errorMessage: 'Cập nhật bản ghi thất bại');
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

      // Note: Deleting from Firebase Auth requires the Admin SDK or the user
      // deleting their own account. Here we only remove the Firestore record;
      // the Auth user still exists but cannot sign in without a Firestore
      // entry. For full deletion, use Firebase Admin SDK or delete from the
      // Firebase Console.

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

  // Find QR token by code4Digits (search in all tokens, returns first match even if used)
  // This is used to get sessionId before checking attendance record
  Future<Map<String, dynamic>?> findQrTokenByCode4Digits(String code4Digits) async {
    try {
      // Query by code4Digits (may need composite index for orderBy, but try without first)
      Query query = _collection('qr_tokens')
          .where('code4Digits', isEqualTo: code4Digits)
          .limit(20); // Limit to avoid too many results
      
      QuerySnapshot snapshot;
      try {
        // Try with orderBy first (preferred - most recent tokens first)
        snapshot = await query.orderBy('createdAt', descending: true).get();
      } catch (e) {
        // If orderBy fails (no index), try without orderBy
        debugPrint('orderBy failed, trying without orderBy: $e');
        snapshot = await query.get();
      }
      
      if (snapshot.docs.isEmpty) return null;
      
      // Return the first token (most recent), even if used - we just need sessionId
      return Map<String, dynamic>.from(snapshot.docs.first.data() as Map);
    } catch (e) {
      debugPrint('Error finding token by code4Digits: $e');
      return null;
    }
  }

  // Find QR token by code4Digits (search in all tokens, only returns active tokens)
  Future<Map<String, dynamic>?> getQrTokenByCode4Digits(String code4Digits) async {
    try {
      // Query by code4Digits (may need composite index for orderBy, but try without first)
      Query query = _collection('qr_tokens')
          .where('code4Digits', isEqualTo: code4Digits)
          .limit(20); // Limit to avoid too many results
      
      QuerySnapshot snapshot;
      try {
        // Try with orderBy first (preferred - most recent tokens first)
        snapshot = await query.orderBy('createdAt', descending: true).get();
      } catch (e) {
        // If orderBy fails (no index), try without orderBy
        debugPrint('orderBy failed, trying without orderBy: $e');
        snapshot = await query.get();
      }
      
      if (snapshot.docs.isEmpty) return null;
      
      // Find the first active (not expired, not used) token
      final now = DateTime.now();
      for (var doc in snapshot.docs) {
        final tokenData = Map<String, dynamic>.from(doc.data() as Map);
        try {
          final expiresAt = DateTime.parse(tokenData['expiresAt'] as String);
          final isUsed = (tokenData['isUsed'] as int) == 1;
          
          if (!isUsed && expiresAt.isAfter(now)) {
            return tokenData;
          }
        } catch (e) {
          // Skip invalid tokens
          debugPrint('Error parsing token data: $e');
          continue;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding token by code4Digits: $e');
      return null;
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

  // ========== NOTIFICATION OPERATIONS ==========

  Future<AppNotification> createNotification(AppNotification notification) async {
    return await _withRetry(() async {
      final notificationsRef = _collection('notifications');
      final docRef = await notificationsRef.add(notification.toMap());
      return notification.copyWith(id: docRef.id);
    }, errorMessage: 'Tạo thông báo thất bại');
  }

  Future<List<AppNotification>> getAllNotifications() async {
    try {
      final snapshot = await _collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AppNotification.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<AppNotification>> getNotificationsByRole(String? role) async {
    try {
      Query query = _collection('notifications');
      
      if (role != null) {
        query = query.where('targetRole', isEqualTo: role);
      } else {
        query = query.where('targetRole', isNull: true);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AppNotification.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notifications by role: $e');
      return [];
    }
  }

  Future<List<AppNotification>> getNotificationsByUser(String userId) async {
    try {
      final snapshot = await _collection('notifications')
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AppNotification.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notifications by user: $e');
      return [];
    }
  }

  Future<int> deleteNotification(String id) async {
    try {
      await _collection('notifications').doc(id).delete();
      return 1;
    } catch (e) {
      throw 'Xóa thông báo thất bại: $e';
    }
  }

  Future<List<AppNotification>> getNotificationsForUser({
    required String userId,
    required String? userRole,
    required List<String>? userClassCodes, // class codes the user belongs to
  }) async {
    try {
      final allNotifications = await getAllNotifications();

      final relevantNotifications = <AppNotification>[];

      for (final notification in allNotifications) {
        bool isRelevant = false;

        // 0. Creator always sees their own notifications (for management)
        if (notification.createdBy == userId) {
          isRelevant = true;
        }
        // 1. Notification targeted at a specific user
        else if (notification.targetUserId == userId) {
          isRelevant = true;
        }
        // 2. Notification targeted at the user's role
        else if (notification.targetRole != null && notification.targetRole == userRole) {
          // If targetClassCode is set, check if user belongs to that class
          if (notification.targetClassCode != null) {
            if (userClassCodes != null && userClassCodes.contains(notification.targetClassCode)) {
              isRelevant = true;
            }
          } else {
            // No classCode set.
            // If creator is a teacher, only deliver to students in classes they teach.
            try {
              final creator = await getUserByUid(notification.createdBy);
              if (creator?.role.name == 'teacher') {
                final teacherSubjects = await getSubjectsByCreator(notification.createdBy);
                final teacherClassCodes = teacherSubjects.map((s) => s.classCode).toSet();

                debugPrint('🔔 Notification from teacher ${notification.createdBy}');
                debugPrint('   - Teacher classes: $teacherClassCodes');
                debugPrint('   - User classes: $userClassCodes');

                // Only show if user has any class taught by the teacher
                if (teacherClassCodes.isNotEmpty) {
                  if (userClassCodes != null && userClassCodes.isNotEmpty) {
                    final hasMatchingClass = userClassCodes.any((code) => teacherClassCodes.contains(code));
                    debugPrint('   - Has matching class: $hasMatchingClass');
                    if (hasMatchingClass) {
                      isRelevant = true;
                    }
                  } else {
                    debugPrint('   - ⚠️ userClassCodes null or empty');
                  }
                } else {
                  debugPrint('   - ⚠️ Teacher has no classes');
                }
              } else {
                // Not a teacher - deliver to all users with that role
                isRelevant = true;
              }
            } catch (e) {
              debugPrint('❌ Error checking creator in getNotificationsForUser: $e');
              // Fall back to delivering to all if creator lookup fails
              isRelevant = true;
            }
          }
        }
        // 3. Notification targeted at a class the user belongs to
        else if (notification.targetClassCode != null && userClassCodes != null) {
          if (userClassCodes.contains(notification.targetClassCode)) {
            isRelevant = true;
          }
        }
        // 4. Broadcast notification (no targetRole, targetUserId, targetClassCode)
        else if (notification.targetRole == null &&
                 notification.targetUserId == null &&
                 notification.targetClassCode == null) {
          isRelevant = true;
        }

        if (isRelevant) {
          relevantNotifications.add(notification);
        }
      }

      return relevantNotifications;
    } catch (e) {
      debugPrint('Error fetching notifications for user: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId, String userId) async {
    try {
      await _withRetry(() async {
        final notificationRef = _collection('notifications').doc(notificationId);
        final doc = await notificationRef.get();
        
        if (!doc.exists) return;
        
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);
        
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          await notificationRef.update({'readBy': readBy});
        }
      }, errorMessage: 'Đánh dấu đã đọc thất bại');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Helper to retry Firestore operations on transient network errors
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    String errorMessage = 'Thao tác thất bại',
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        final isNetworkError = _isNetworkError(e);

        if (!isNetworkError || attempt >= maxRetries) {
          // Not a network error, or out of retries
          throw '$errorMessage: $e';
        }

        // Network error - retry with exponential backoff
        debugPrint('⚠️ Network error (attempt $attempt/$maxRetries): $e. Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 2).round());
      }
    }

    throw '$errorMessage: Đã thử $maxRetries lần nhưng vẫn thất bại';
  }

  // Detect transient network errors so we can retry
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    final networkKeywords = [
      'network',
      'unavailable',
      'timeout',
      'connection',
      'internet',
      'offline',
      'failed to get document',
      'deadline exceeded',
      'unreachable',
    ];

    return networkKeywords.any((keyword) => errorString.contains(keyword));
  }
}
