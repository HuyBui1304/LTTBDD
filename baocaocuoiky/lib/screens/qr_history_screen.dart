import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;
import '../providers/auth_provider.dart';

class QRHistoryScreen extends StatefulWidget {
  const QRHistoryScreen({super.key});

  @override
  State<QRHistoryScreen> createState() => _QRHistoryScreenState();
}

class _QRHistoryScreenState extends State<QRHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get user ID from database
      final userMaps = await _db.database.then((db) => db.query(
        'users',
        where: 'uid = ?',
        whereArgs: [currentUser.uid],
      ));
      
      if (userMaps.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      
      final userId = userMaps.first['id'] as int;
      final history = await _db.getQRScanHistoryByUser(userId);
      
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử quét QR'),
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải lịch sử...')
          : _history.isEmpty
              ? custom.EmptyWidget(
                  icon: Icons.history,
                  title: 'Chưa có lịch sử quét',
                  message: 'Lịch sử quét mã QR sẽ được lưu tại đây',
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final scanType = item['scanType'] as String;
                      final note = item['note'] as String?;
                      final scannedAt = DateTime.parse(item['scannedAt'] as String);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getScanTypeColor(scanType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getScanTypeIcon(scanType),
                              color: _getScanTypeColor(scanType),
                            ),
                          ),
                          title: Text(
                            _getScanTypeTitle(scanType),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note != null) ...[
                                const SizedBox(height: 4),
                                Text(note),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(scannedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getScanTypeIcon(String scanType) {
    switch (scanType) {
      case 'student_attendance':
        return Icons.check_circle;
      case 'session_view':
        return Icons.qr_code;
      default:
        return Icons.qr_code_scanner;
    }
  }

  Color _getScanTypeColor(String scanType) {
    switch (scanType) {
      case 'student_attendance':
        return Colors.green;
      case 'session_view':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getScanTypeTitle(String scanType) {
    switch (scanType) {
      case 'student_attendance':
        return 'Điểm danh sinh viên';
      case 'session_view':
        return 'Xem thông tin buổi học';
      default:
        return 'Quét mã QR';
    }
  }
}

