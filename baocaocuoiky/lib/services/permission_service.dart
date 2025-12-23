import 'package:flutter/material.dart';
import '../models/app_user.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._init();
  
  PermissionService._init();

  // Admin: Toàn quyền
  bool canManageUsers(UserRole role) => role == UserRole.admin;
  bool canDeleteUsers(UserRole role) => role == UserRole.admin;
  bool canEditUsers(UserRole role) => role == UserRole.admin;
  
  // Teacher + Admin: Tạo và quản lý buổi học
  bool canCreateSession(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  bool canManageSessions(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  bool canViewAllSessions(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  
  // Teacher + Admin: Tạo QR, xuất file
  bool canCreateQR(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  bool canExportData(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  bool canViewReports(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  
  // All: Quét QR, xem lịch sử
  bool canScanQR(UserRole role) => true;
  bool canViewOwnHistory(UserRole role) => true;
  
  // Teacher + Admin: Xem tất cả học sinh
  bool canViewAllStudents(UserRole role) => role == UserRole.admin || role == UserRole.teacher;
  
  // Session management
  bool canEditSession(UserRole role, {required int sessionCreatorId, required int currentUserId}) {
    if (role == UserRole.admin) return true;
    if (role == UserRole.teacher && sessionCreatorId == currentUserId) return true;
    return false;
  }

  bool canDeleteSession(UserRole role, {required int sessionCreatorId, required int currentUserId}) {
    if (role == UserRole.admin) return true;
    if (role == UserRole.teacher && sessionCreatorId == currentUserId) return true;
    return false;
  }

  // UI helpers
  List<Widget> getActionsForRole(UserRole role, BuildContext context) {
    final actions = <Widget>[];

    if (canCreateSession(role)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // Navigate to create
          },
          tooltip: 'Tạo mới',
        ),
      );
    }

    if (canViewReports(role)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () {
            // Navigate to reports
          },
          tooltip: 'Báo cáo',
        ),
      );
    }

    return actions;
  }

  // Role-based UI visibility
  bool shouldShowButton(String action, UserRole role) {
    switch (action) {
      case 'create':
        return canCreateSession(role);
      case 'approve':
        return role == UserRole.admin || role == UserRole.teacher;
      case 'delete':
        return role == UserRole.admin;
      case 'edit':
        return role == UserRole.admin || role == UserRole.teacher;
      case 'export':
        return canExportData(role);
      case 'manage_users':
        return canManageUsers(role);
      default:
        return false;
    }
  }

  // Get available actions for session
  List<String> getAvailableActions(
    UserRole role, {
    required int sessionCreatorId,
    required int currentUserId,
  }) {
    final actions = <String>[];

    if (role.canView) actions.add('view');
    
    if (canEditSession(role, sessionCreatorId: sessionCreatorId, currentUserId: currentUserId)) {
      actions.add('edit');
    }

    if (canDeleteSession(role, sessionCreatorId: sessionCreatorId, currentUserId: currentUserId)) {
      actions.add('delete');
    }

    if (role == UserRole.admin || role == UserRole.teacher) {
      actions.add('approve');
    }

    return actions;
  }
}

