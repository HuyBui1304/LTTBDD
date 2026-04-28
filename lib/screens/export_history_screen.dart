import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/export_history.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

class ExportHistoryScreen extends StatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<ExportHistory> _history = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, csv, pdf

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

      if (currentUser == null) return;

      // Get numeric id from UID (hash-based for Firebase compatibility)
      final userId = _db.uidToUserId(currentUser.uid);

      final historyMaps = authProvider.isAdmin
          ? await _db.getAllExportHistory()
          : await _db.getExportHistoryByUser(userId);

      setState(() {
        _history = historyMaps.map((map) => ExportHistory.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<ExportHistory> get _filteredHistory {
    if (_filter == 'all') return _history;
    return _history.where((h) => h.format == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử xuất dữ liệu'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'csv', child: Text('CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('PDF')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có lịch sử xuất dữ liệu nào'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredHistory[index];
                      return _buildHistoryCard(entry);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(ExportHistory entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getFormatColor(entry.format).withOpacity(0.2),
          child: Icon(
            _getFormatIcon(entry.format),
            color: _getFormatColor(entry.format),
          ),
        ),
        title: Text(
          _getExportTypeText(entry.exportType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Định dạng: ${entry.format.toUpperCase()}'),
            Text('Người xuất: ${entry.userName}'),
            Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(entry.exportedAt)}'),
            if (entry.fileName != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.fileName!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xóa lịch sử'),
                content: const Text('Bạn có chắc muốn xóa mục này khỏi lịch sử?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true && entry.id != null) {
              await _db.deleteExportHistory(entry.id!);
              await _loadHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa khỏi lịch sử')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _getExportTypeText(String type) {
    switch (type) {
      case 'students':
        return 'Danh sách sinh viên';
      case 'sessions':
        return 'Danh sách buổi học';
      case 'attendance':
        return 'Bảng điểm danh';
      case 'full_report':
        return 'Báo cáo tổng hợp';
      default:
        return type;
    }
  }

  IconData _getFormatIcon(String format) {
    return format == 'csv' ? Icons.table_chart : Icons.picture_as_pdf;
  }

  Color _getFormatColor(String format) {
    return format == 'csv' ? Colors.green : Colors.red;
  }
}

