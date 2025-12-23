import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/attendance_session.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService instance = RealtimeNotificationService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  Timer? _timer;
  final StreamController<SessionStatusUpdate> _statusController = StreamController.broadcast();
  
  RealtimeNotificationService._init();

  Stream<SessionStatusUpdate> get statusStream => _statusController.stream;

  // Start monitoring session status changes (simulated real-time)
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkForUpdates();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkForUpdates() async {
    try {
      // Check for scheduled sessions that should be completed
      final sessions = await _db.getAllSessions();
      final now = DateTime.now();

      for (final session in sessions) {
        // Skip sessions without sessionDate
        if (session.sessionDate == null) continue;
        
        // Auto-complete sessions that are past their time (more than 2 hours)
        if (session.status == SessionStatus.scheduled &&
            session.sessionDate!.isBefore(now.subtract(const Duration(hours: 2)))) {
          await _db.updateSession(session.copyWith(status: SessionStatus.completed));
          _statusController.add(SessionStatusUpdate(
            sessionId: session.id!,
            sessionTitle: session.title,
            oldStatus: SessionStatus.scheduled,
            newStatus: SessionStatus.completed,
            message: 'Buổi học "${session.title}" đã tự động hoàn thành',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error checking updates: $e');
    }
  }

  // Manual notification (for user actions)
  void notifyStatusChange(SessionStatusUpdate update) {
    _statusController.add(update);
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}

class SessionStatusUpdate {
  final int sessionId;
  final String sessionTitle;
  final SessionStatus oldStatus;
  final SessionStatus newStatus;
  final String message;
  final DateTime timestamp;

  SessionStatusUpdate({
    required this.sessionId,
    required this.sessionTitle,
    required this.oldStatus,
    required this.newStatus,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'SessionStatusUpdate{sessionId: $sessionId, newStatus: $newStatus, message: $message}';
  }
}

// Widget to display real-time notifications
class RealtimeNotificationListener extends StatefulWidget {
  final Widget child;

  const RealtimeNotificationListener({super.key, required this.child});

  @override
  State<RealtimeNotificationListener> createState() => _RealtimeNotificationListenerState();
}

class _RealtimeNotificationListenerState extends State<RealtimeNotificationListener> {
  StreamSubscription<SessionStatusUpdate>? _subscription;

  @override
  void initState() {
    super.initState();
    RealtimeNotificationService.instance.startMonitoring();
    _subscription = RealtimeNotificationService.instance.statusStream.listen((update) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _getStatusIcon(update.newStatus),
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(update.message),
                ),
              ],
            ),
            backgroundColor: _getStatusColor(update.newStatus),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Xem',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to session detail
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Icons.schedule;
      case SessionStatus.completed:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.completed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

