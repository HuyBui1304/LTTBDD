import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _error = '';
  String? _selectedTable;
  int _currentPage = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = '';
        _currentPage = 0;
      });
    }

    try {
      final offset = loadMore ? _currentPage * _pageSize : 0;
      final logs = await _dbHelper.getAuditLogs(
        tableName: _selectedTable,
        limit: _pageSize,
        offset: offset,
      );

      setState(() {
        if (loadMore) {
          _logs.addAll(logs);
          _currentPage++;
        } else {
          _logs = logs;
          _currentPage = 1;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải lịch sử: $e';
        _isLoading = false;
      });
    }
  }

  String _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return '➕';
      case 'UPDATE':
        return '✏️';
      case 'DELETE':
        return '🗑️';
      default:
        return '📝';
    }
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thao tác'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc theo bảng',
            onSelected: (value) {
              setState(() {
                _selectedTable = value;
              });
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(value: null, child: Text('Tất cả')),
              const PopupMenuItem(value: 'students', child: Text('Sinh viên')),
              const PopupMenuItem(value: 'class_schedules', child: Text('Lịch học')),
            ],
          ),
        ],
      ),
      body: _isLoading && _logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadLogs(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có lịch sử thao tác nào',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadLogs(),
                      child: ListView.builder(
                        itemCount: _logs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _logs.length) {
                            // Load more button
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => _loadLogs(loadMore: true),
                                  child: const Text('Tải thêm'),
                                ),
                              ),
                            );
                          }

                          final log = _logs[index];
                          final action = log['action'] as String;
                          final tableName = log['tableName'] as String;
                          final recordId = log['recordId'] as int;
                          final timestamp = DateTime.fromMillisecondsSinceEpoch(log['timestamp'] as int);
                          final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getActionColor(action),
                                child: Text(
                                  _getActionIcon(action),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                '$action ${tableName == 'students' ? 'Sinh viên' : 'Lịch học'} #$recordId',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bảng: ${tableName == 'students' ? 'Sinh viên' : 'Lịch học'}'),
                                  Text('Thời gian: ${dateFormat.format(timestamp)}'),
                                ],
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

