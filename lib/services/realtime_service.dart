import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_database_service.dart';
import '../models/attendance_session.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService instance = RealtimeNotificationService._init();
  final FirebaseDatabaseService _db = FirebaseDatabaseService.instance;
  final CollectionReference _sessionsRef = FirebaseFirestore.instance.collection('attendance_sessions');
  
  StreamSubscription<QuerySnapshot>? _sessionsSubscription;
  Timer? _timer;
  final StreamController<SessionStatusUpdate> _statusController = StreamController.broadcast();
  
  RealtimeNotificationService._init();

  Stream<SessionStatusUpdate> get statusStream => _statusController.stream;

  // Start monitoring session status changes using Firestore listeners
  void startMonitoring() {
    _sessionsSubscription?.cancel();
    
    try {
      // Listen to all session changes with error handling
      _sessionsSubscription = _sessionsRef.snapshots().listen(
        (snapshot) {
          _processSessionUpdates(snapshot);
        },
        onError: (error) {
          debugPrint('Error in Firestore listener: $error');
          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_sessionsSubscription == null) {
              startMonitoring();
            }
          });
        },
      );

      // Also check for auto-completion periodically (as backup)
      _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
        await _checkForAutoCompletion();
      });
    } catch (e) {
      debugPrint('Error starting monitoring: $e');
    }
  }

  void stopMonitoring() {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;
    _timer?.cancel();
    _timer = null;
  }

  void _processSessionUpdates(QuerySnapshot snapshot) {
    try {
      if (snapshot.docs.isEmpty) return;
      
      for (var doc in snapshot.docs) {
          try {
          final sessionMap = Map<String, dynamic>.from(doc.data() as Map);
            final session = AttendanceSession.fromMap(sessionMap);
            
            // Check if session should be auto-completed
            if (session.sessionDate != null &&
                session.status == SessionStatus.scheduled &&
                session.sessionDate!.isBefore(DateTime.now().subtract(const Duration(hours: 2)))) {
              // Auto-complete in background
              _autoCompleteSession(session);
            }
          } catch (e) {
            debugPrint('Error processing session update: $e');
          }
      }
    } catch (e) {
      debugPrint('Error processing session updates: $e');
    }
  }

  Future<void> _checkForAutoCompletion() async {
    try {
      final sessions = await _db.getAllSessions();
      final now = DateTime.now();

      for (final session in sessions) {
        if (session.sessionDate == null) continue;
        
        if (session.status == SessionStatus.scheduled &&
            session.sessionDate!.isBefore(now.subtract(const Duration(hours: 2)))) {
          await _autoCompleteSession(session);
        }
      }
    } catch (e) {
      debugPrint('Error checking auto-completion: $e');
    }
  }

  Future<void> _autoCompleteSession(AttendanceSession session) async {
    try {
      await _db.updateSession(session.copyWith(status: SessionStatus.completed));
      _statusController.add(SessionStatusUpdate(
        sessionId: session.id!,
        sessionTitle: session.title,
        oldStatus: SessionStatus.scheduled,
        newStatus: SessionStatus.completed,
        message: 'Buổi học "${session.title}" đã tự động hoàn thành',
      ));
    } catch (e) {
      debugPrint('Error auto-completing session: $e');
    }
  }

  // Manual notification (for user actions)
  void notifyStatusChange(SessionStatusUpdate update) {
    _statusController.add(update);
  }

  void dispose() {
    stopMonitoring();
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
  final bool shouldMonitor;

  const RealtimeNotificationListener({
    super.key, 
    required this.child,
    this.shouldMonitor = false,
  });

  @override
  State<RealtimeNotificationListener> createState() => _RealtimeNotificationListenerState();
}

class _RealtimeNotificationListenerState extends State<RealtimeNotificationListener> {
  StreamSubscription<SessionStatusUpdate>? _subscription;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    // Don't start monitoring immediately - wait for user to be authenticated
  }

  @override
  void didUpdateWidget(RealtimeNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start/stop monitoring based on shouldMonitor prop
    if (widget.shouldMonitor && !_isMonitoring) {
      _startMonitoring();
    } else if (!widget.shouldMonitor && _isMonitoring) {
      _stopMonitoring();
    }
  }

  void _startMonitoring() {
    if (_isMonitoring) return;
    try {
      _isMonitoring = true;
      RealtimeNotificationService.instance.startMonitoring();
      _subscription = RealtimeNotificationService.instance.statusStream.listen(
        (update) {
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
        },
        onError: (error) {
          debugPrint('Error in notification stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting monitoring: $e');
      _isMonitoring = false;
    }
  }

  void _stopMonitoring() {
    if (!_isMonitoring) return;
    try {
      _isMonitoring = false;
      _subscription?.cancel();
      _subscription = null;
      RealtimeNotificationService.instance.stopMonitoring();
    } catch (e) {
      debugPrint('Error stopping monitoring: $e');
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
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
