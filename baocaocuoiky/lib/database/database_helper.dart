// This file now re-exports FirebaseDatabaseService as DatabaseHelper for backward compatibility
// All existing code using DatabaseHelper will automatically use Firebase Realtime Database

// Import models for type references
import '../models/student.dart';
import '../models/subject.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import 'firebase_database_service.dart' as firebase;

// Export for convenience
export 'firebase_database_service.dart' show FirebaseDatabaseService, Crypto;

/// DatabaseHelper is now a wrapper for FirebaseDatabaseService
/// This allows all existing code to work without changes
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  // Delegate to FirebaseDatabaseService
  final firebase.FirebaseDatabaseService _firebaseService = firebase.FirebaseDatabaseService.instance;

  DatabaseHelper._init();

  // Delegate all methods to FirebaseDatabaseService
  Future<Student> createStudent(Student student) => _firebaseService.createStudent(student);
  Future<Student?> getStudent(int id) => _firebaseService.getStudent(id);
  Future<List<Student>> getAllStudents() => _firebaseService.getAllStudents();
  Future<List<Student>> searchStudents(String query) => _firebaseService.searchStudents(query);
  Future<List<Student>> getStudentsByClass(String classCode) => _firebaseService.getStudentsByClass(classCode);
  Future<Student?> getStudentByStudentId(String studentId) => _firebaseService.getStudentByStudentId(studentId);
  Future<int> updateStudent(Student student) => _firebaseService.updateStudent(student);
  Future<int> deleteStudent(int id) => _firebaseService.deleteStudent(id);

  Future<Subject> createSubject(Subject subject) => _firebaseService.createSubject(subject);
  Future<Subject?> getSubject(int id) => _firebaseService.getSubject(id);
  Future<List<Subject>> getAllSubjects() => _firebaseService.getAllSubjects();
  Future<List<Subject>> getSubjectsByCreator(int creatorId) => _firebaseService.getSubjectsByCreator(creatorId);
  Future<int> updateSubject(Subject subject) => _firebaseService.updateSubject(subject);
  Future<int> deleteSubject(int id) => _firebaseService.deleteSubject(id);

  Future<AttendanceSession> createSession(AttendanceSession session) => _firebaseService.createSession(session);
  Future<AttendanceSession?> getSession(int id) => _firebaseService.getSession(id);
  Future<List<AttendanceSession>> getAllSessions() => _firebaseService.getAllSessions();
  Future<List<AttendanceSession>> getSessionsByCreator(int creatorId) => _firebaseService.getSessionsByCreator(creatorId);
  Future<List<AttendanceSession>> getSessionsBySubject(int subjectId) => _firebaseService.getSessionsBySubject(subjectId);
  Future<int> updateSession(AttendanceSession session) => _firebaseService.updateSession(session);
  Future<int> deleteSession(int id) => _firebaseService.deleteSession(id);

  Future<AttendanceRecord> createRecord(AttendanceRecord record) => _firebaseService.createRecord(record);
  Future<AttendanceRecord?> getRecord(int id) => _firebaseService.getRecord(id);
  Future<List<AttendanceRecord>> getRecordsBySession(int sessionId) => _firebaseService.getRecordsBySession(sessionId);
  Future<List<AttendanceRecord>> getRecordsByStudent(int studentId) => _firebaseService.getRecordsByStudent(studentId);
  Future<AttendanceRecord?> getRecordBySessionAndStudent(int sessionId, int studentId) => _firebaseService.getRecordBySessionAndStudent(sessionId, studentId);
  Future<int> updateRecord(AttendanceRecord record) => _firebaseService.updateRecord(record);
  Future<int> deleteRecord(int id) => _firebaseService.deleteRecord(id);

  Future<Map<String, int>> getSessionStats(int sessionId) => _firebaseService.getSessionStats(sessionId);
  Future<Map<String, dynamic>> getStudentStats(int studentId) => _firebaseService.getStudentStats(studentId);

  Future<AppUser> createUser(AppUser user) => _firebaseService.createUser(user);
  Future<AppUser?> getUserByUid(String uid) => _firebaseService.getUserByUid(uid);
  Future<AppUser?> getUserByEmail(String email) => _firebaseService.getUserByEmail(email);
  Future<List<AppUser>> getAllUsers() => _firebaseService.getAllUsers();
  Future<List<AppUser>> getUsersByRole(UserRole role) => _firebaseService.getUsersByRole(role);
  Future<int> updateUser(AppUser user) => _firebaseService.updateUser(user);
  Future<int> updateUserLastLogin(String uid) => _firebaseService.updateUserLastLogin(uid);
  Future<int> deleteUser(String uid) => _firebaseService.deleteUser(uid);

  Future<void> createQrToken(Map<String, dynamic> tokenData) => _firebaseService.createQrToken(tokenData);
  Future<Map<String, dynamic>?> getQrTokenByToken(String token) => _firebaseService.getQrTokenByToken(token);
  Future<void> updateQrToken(String token, Map<String, dynamic> updates) => _firebaseService.updateQrToken(token, updates);

  Future<void> addQrScanHistory(Map<String, dynamic> historyData) => _firebaseService.addQrScanHistory(historyData);
  Future<List<Map<String, dynamic>>> getQrScanHistoryByUser(int userId) => _firebaseService.getQrScanHistoryByUser(userId);

  Future<void> addSessionHistory(Map<String, dynamic> historyData) => _firebaseService.addSessionHistory(historyData);
  Future<List<Map<String, dynamic>>> getSessionHistory(int sessionId) => _firebaseService.getSessionHistory(sessionId);

  Future<void> addExportHistory(Map<String, dynamic> exportData) => _firebaseService.addExportHistory(exportData);
  Future<List<Map<String, dynamic>>> getExportHistoryByUser(int userId) => _firebaseService.getExportHistoryByUser(userId);

  Future<int?> getUserId(String uid) => _firebaseService.getUserId(uid);

  // Helper method to convert UID to numeric ID (hash-based)
  int uidToUserId(String uid) {
    // Convert UID to positive int using hash
    return uid.hashCode & 0x7FFFFFFF;
  }

  // Additional methods
  Future<AttendanceSession?> getSessionByCode(String sessionCode) => _firebaseService.getSessionByCode(sessionCode);
  Future<List<AttendanceSession>> getSessionsByStudentClass(String classCode) => _firebaseService.getSessionsByStudentClass(classCode);
  Future<List<Map<String, dynamic>>> getQrTokensBySession(int sessionId) => _firebaseService.getQrTokensBySession(sessionId);
  Future<int> deleteExpiredQrTokens() => _firebaseService.deleteExpiredQrTokens();
  Future<List<Map<String, dynamic>>> getAllExportHistory() => _firebaseService.getAllExportHistory();
  Future<void> deleteExportHistory(int id) => _firebaseService.deleteExportHistory(id);
  Future<void> createSessionHistory(Map<String, dynamic> historyData) => _firebaseService.createSessionHistory(historyData);
  Future<void> createQRScanHistory(Map<String, dynamic> historyData) => _firebaseService.createQRScanHistory(historyData);
  Future<void> createExportHistory(Map<String, dynamic> exportData) => _firebaseService.createExportHistory(exportData);
  Future<Map<String, dynamic>> exportAllData() => _firebaseService.exportAllData();
}
