import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../models/attendance_session.dart';
import '../services/export_service.dart';
import '../widgets/state_widgets.dart' as custom;
import '../widgets/custom_text_field.dart';

class ExportSessionsScreen extends StatefulWidget {
  const ExportSessionsScreen({super.key});

  @override
  State<ExportSessionsScreen> createState() => _ExportSessionsScreenState();
}

class _ExportSessionsScreenState extends State<ExportSessionsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ExportService _exportService = ExportService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Subject> _allSubjects = [];
  List<Subject> _filteredSubjects = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _db.getAllSubjects();
      setState(() {
        _allSubjects = subjects;
        _applyFilters();
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

  void _applyFilters() {
    var filtered = _allSubjects;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.classCode.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    filtered.sort((a, b) => a.subjectName.compareTo(b.subjectName));

    setState(() {
      _filteredSubjects = filtered;
    });
  }

  Future<void> _showExportOptions(Subject subject) async {
    // Lấy tất cả sessions của môn học
    final sessions = await _db.getAllSessions();
    final subjectSessions = sessions.where((s) => s.subjectId == subject.id).toList();

    if (subjectSessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Môn học này chưa có buổi học nào')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xuất dữ liệu - ${subject.subjectName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Môn học có ${subjectSessions.length} buổi học'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Xuất toàn bộ'),
              subtitle: const Text('Tất cả các buổi học của môn này'),
              onTap: () {
                Navigator.pop(context);
                _exportAllSessions(subject, subjectSessions);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Chọn buổi học cụ thể'),
              subtitle: const Text('Chọn từng buổi để xuất'),
              onTap: () {
                Navigator.pop(context);
                _showSessionSelection(subject, subjectSessions);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllSessions(Subject subject, List<AttendanceSession> sessions) async {
    setState(() => _isExporting = true);
    try {
      final filePath = await _exportService.exportSessionsBySubjectToCSV(
        subject: subject,
        sessions: sessions,
      );
      
      setState(() => _isExporting = false);
      
      if (mounted) {
        _showExportSuccessDialog(filePath, 'csv');
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSessionSelection(Subject subject, List<AttendanceSession> sessions) async {
    final selectedSessions = <AttendanceSession>[];
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chọn buổi học - ${subject.subjectName}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...sessions.map((session) {
                    final isSelected = selectedSessions.contains(session);
                    return CheckboxListTile(
                      title: Text(session.title),
                      subtitle: Text('Buổi ${session.sessionNumber}'),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedSessions.add(session);
                          } else {
                            selectedSessions.remove(session);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: selectedSessions.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _exportSelectedSessions(subject, selectedSessions);
                    },
              child: Text('Xuất (${selectedSessions.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSelectedSessions(Subject subject, List<AttendanceSession> sessions) async {
    setState(() => _isExporting = true);
    try {
      final filePath = await _exportService.exportSessionsBySubjectToCSV(
        subject: subject,
        sessions: sessions,
      );
      
      setState(() => _isExporting = false);
      
      if (mounted) {
        _showExportSuccessDialog(filePath, 'csv');
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog(String filePath, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất file thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File đã được lưu tại:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất dữ liệu buổi học'),
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xuất file...'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchTextField(
                    controller: _searchController,
                    hint: 'Tìm kiếm môn học...',
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() => _searchQuery = '');
                      _applyFilters();
                    },
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const custom.LoadingWidget(message: 'Đang tải danh sách môn học...')
                      : _filteredSubjects.isEmpty
                          ? custom.EmptyWidget(
                              icon: Icons.class_outlined,
                              title: _searchQuery.isNotEmpty
                                  ? 'Không tìm thấy môn học'
                                  : 'Chưa có môn học nào',
                              message: _searchQuery.isNotEmpty
                                  ? 'Thử tìm kiếm với từ khóa khác'
                                  : 'Chưa có môn học trong hệ thống',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = _filteredSubjects[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.class_,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      subject.subjectName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Mã môn: ${subject.subjectCode}'),
                                        Text('Lớp: ${subject.classCode}'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _showExportOptions(subject),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

