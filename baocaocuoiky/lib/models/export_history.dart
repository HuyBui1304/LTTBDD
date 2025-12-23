import 'package:intl/intl.dart';

class ExportHistory {
  final int? id;
  final int userId;
  final String userName;
  final String exportType; // 'students', 'sessions', 'attendance', 'full_report'
  final String format; // 'csv' or 'pdf'
  final String? fileName;
  final String? filePath;
  final DateTime exportedAt;
  final Map<String, dynamic>? filters; // Store filter criteria used

  ExportHistory({
    this.id,
    required this.userId,
    required this.userName,
    required this.exportType,
    required this.format,
    this.fileName,
    this.filePath,
    DateTime? exportedAt,
    this.filters,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'exportType': exportType,
      'format': format,
      'fileName': fileName,
      'filePath': filePath,
      'exportedAt': exportedAt.toIso8601String(),
      'filters': filters?.toString(),
    };
  }

  factory ExportHistory.fromMap(Map<String, dynamic> map) {
    return ExportHistory(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      userName: map['userName'] as String,
      exportType: map['exportType'] as String,
      format: map['format'] as String,
      fileName: map['fileName'] as String?,
      filePath: map['filePath'] as String?,
      exportedAt: DateTime.parse(map['exportedAt'] as String),
      filters: null, // TODO: Parse from string if needed
    );
  }

  @override
  String toString() {
    return 'ExportHistory{id: $id, exportType: $exportType, format: $format, exportedAt: ${DateFormat('dd/MM/yyyy HH:mm').format(exportedAt)}}';
  }
}

