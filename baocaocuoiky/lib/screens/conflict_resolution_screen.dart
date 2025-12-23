import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../models/student.dart';
import '../models/attendance_session.dart';
import 'package:intl/intl.dart';

class ConflictResolutionScreen extends StatefulWidget {
  final List<ConflictData> conflicts;
  final Map<String, dynamic> importData;

  const ConflictResolutionScreen({
    super.key,
    required this.conflicts,
    required this.importData,
  });

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  final Map<String, bool> _selections = {}; // true = keepLocal, false = keepRemote
  final SyncService _syncService = SyncService.instance;

  @override
  void initState() {
    super.initState();
    // Default: keep local
    for (final conflict in widget.conflicts) {
      _selections[conflict.conflictField] = true;
    }
  }

  Future<void> _applyResolutions() async {
    try {
      // Apply manual resolutions
      for (final conflict in widget.conflicts) {
        final keepLocal = _selections[conflict.conflictField] ?? true;
        await _syncService.resolveConflictManually(conflict, keepLocal);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã giải quyết xung đột thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải quyết xung đột'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Keep all local
              setState(() {
                for (final conflict in widget.conflicts) {
                  _selections[conflict.conflictField] = true;
                }
              });
            },
            icon: const Icon(Icons.phone_android, color: Colors.white),
            label: const Text('Giữ tất cả local', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () {
              // Keep all remote
              setState(() {
                for (final conflict in widget.conflicts) {
                  _selections[conflict.conflictField] = false;
                }
              });
            },
            icon: const Icon(Icons.cloud, color: Colors.white),
            label: const Text('Giữ tất cả remote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tìm thấy ${widget.conflicts.length} xung đột. Chọn phiên bản muốn giữ.',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Conflicts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.conflicts.length,
              itemBuilder: (context, index) {
                final conflict = widget.conflicts[index];
                return _ConflictCard(
                  conflict: conflict,
                  isLocalSelected: _selections[conflict.conflictField] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _selections[conflict.conflictField] = value;
                    });
                  },
                );
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyResolutions,
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final ConflictData conflict;
  final bool isLocalSelected;
  final ValueChanged<bool> onChanged;

  const _ConflictCard({
    required this.conflict,
    required this.isLocalSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  conflict.local is Student ? Icons.person : Icons.event,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTitle(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Local Version
            _VersionOption(
              title: 'Local (Trên máy)',
              isSelected: isLocalSelected,
              onTap: () => onChanged(true),
              child: _buildDataWidget(conflict.local),
            ),

            const SizedBox(height: 12),

            // Remote Version
            _VersionOption(
              title: 'Remote (Import)',
              isSelected: !isLocalSelected,
              onTap: () => onChanged(false),
              child: _buildDataWidget(conflict.remote),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (conflict.local is Student) {
      final student = conflict.local as Student;
      return 'Sinh viên: ${student.name}';
    } else if (conflict.local is AttendanceSession) {
      final session = conflict.local as AttendanceSession;
      return 'Buổi học: ${session.title}';
    }
    return 'Unknown';
  }

  Widget _buildDataWidget(dynamic data) {
    if (data is Student) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mã SV: ${data.studentId}'),
          Text('Email: ${data.email}'),
          Text('SĐT: ${data.phone ?? "N/A"}'),
          Text('Lớp: ${data.classCode}'),
          Text(
            'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(data.updatedAt)}',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      );
    } else if (data is AttendanceSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mã: ${data.sessionCode}'),
          Text('Lớp: ${data.classCode}'),
          Text('Ngày: ${data.sessionDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(data.sessionDate!) : 'Chưa có ngày'}'),
          Text('Trạng thái: ${data.status.displayName}'),
          Text(
            'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(data.updatedAt)}',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }
    return const Text('Unknown data type');
  }
}

class _VersionOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _VersionOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

