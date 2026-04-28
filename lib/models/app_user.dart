enum UserRole {
  admin,    // Administrator - full access
  teacher,  // Teacher - create classes, QR, export
  student,  // Student - scan QR, view history
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.teacher:
        return 'Giáo viên';
      case UserRole.student:
        return 'Học sinh';
    }
  }

  // Permissions
  // Admin: full access
  bool get canManageUsers => this == UserRole.admin;
  bool get canDeleteUsers => this == UserRole.admin;
  bool get canEditUsers => this == UserRole.admin;

  // Teacher: create classes, QR, export
  bool get canCreateSession => this == UserRole.admin || this == UserRole.teacher;
  bool get canCreateQR => this == UserRole.admin || this == UserRole.teacher;
  bool get canExportData => this == UserRole.admin || this == UserRole.teacher;
  bool get canViewReports => this == UserRole.admin || this == UserRole.teacher;

  // Student: scan QR, view history
  bool get canScanQR => true; // Anyone can scan
  bool get canViewOwnHistory => true; // Anyone can view their own history
  
  // Admin + Teacher
  bool get canViewAllStudents => this == UserRole.admin || this == UserRole.teacher;
  bool get canViewAllSessions => this == UserRole.admin || this == UserRole.teacher;
  bool get canManageSessions => this == UserRole.admin || this == UserRole.teacher;
  
  // Legacy (backward compatibility)
  bool get canCreate => canCreateSession;
  bool get canEdit => this == UserRole.admin || this == UserRole.teacher;
  bool get canDelete => this == UserRole.admin;
  bool get canView => true;
  bool get canApprove => this == UserRole.admin || this == UserRole.teacher;
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String passwordHash; // For local auth
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    this.photoUrl,
    this.role = UserRole.student, // Default to student
    DateTime? createdAt,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'passwordHash': passwordHash,
      'photoUrl': photoUrl,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create from Database Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      passwordHash: map['passwordHash'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student, // Default to student
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? passwordHash,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;
  
  // Legacy
  bool get isUser => role == UserRole.student;

  @override
  String toString() {
    return 'AppUser{uid: $uid, email: $email, displayName: $displayName, role: $role}';
  }
}

