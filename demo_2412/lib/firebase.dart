import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ==================== MAIN APP ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBJbZvhHrBt5Fcz8sHMZxqRDToG-i2svS0',
          appId: '1:347517073830:android:798067b9d60fb841f53767',
          messagingSenderId: '347517073830',
          projectId: 'demo2412-524fa',
          databaseURL: 'https://demo2412-524fa-default-rtdb.asia-southeast1.firebasedatabase.app',
          storageBucket: 'demo2412-524fa.firebasestorage.app',
        ),
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      if (!e.toString().contains('duplicate-app') && 
          !e.toString().contains('already exists')) {
        print('❌ Lỗi khởi tạo Firebase: $e');
      }
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Demo'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesScreen()),
              ),
              icon: const Icon(Icons.note),
              label: const Text('Quản lý Ghi chú'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showUserIdDialog(context),
              icon: const Icon(Icons.chat),
              label: const Text('Chat Firebase'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserIdDialog(BuildContext context) {
    final userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập tên hoặc ID của bạn:'),
            const SizedBox(height: 16),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'VD: User1, User2, Linh...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 Mở 2 thiết bị với 2 ID khác nhau để chat qua lại!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = userIdController.text.trim();
              if (userId.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(userId: userId),
                  ),
                );
              }
            },
            child: const Text('Vào Chat'),
          ),
        ],
      ),
    );
  }
}

// ==================== FIREBASE SERVICE (HTTP) ====================
class FirebaseService {
  // URL Firebase Realtime Database
  static const String databaseUrl =
      'https://demo2412-524fa-default-rtdb.asia-southeast1.firebasedatabase.app';

  // GET - Lấy dữ liệu
  static Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$databaseUrl/$path.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data != null ? Map<String, dynamic>.from(data) : null;
      }
    } catch (e) {
      print('Error getting data: $e');
    }
    return null;
  }

  // POST - Thêm dữ liệu mới
  static Future<bool> postData(String path, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$databaseUrl/$path.json'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error posting data: $e');
    }
    return false;
  }

  // DELETE - Xóa dữ liệu
  static Future<bool> deleteData(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('$databaseUrl/$path.json'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting data: $e');
    }
    return false;
  }
}

// ==================== NOTES SCREEN ====================
class NoteModel {
  final String? id;
  final String title;
  final String content;

  NoteModel({this.id, required this.title, required this.content});

  factory NoteModel.fromJson(String id, Map<String, dynamic> json) {
    return NoteModel(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      isLoading = true;
    });

    final data = await FirebaseService.getData('notes');

    setState(() {
      isLoading = false;
      if (data != null) {
        notes = data.entries
            .map(
              (e) => NoteModel.fromJson(e.key, Map<String, dynamic>.from(e.value)),
            )
            .toList();
      } else {
        notes = [];
      }
    });
  }

  Future<void> _addNote(String title, String content) async {
    final success = await FirebaseService.postData('notes', {
      'title': title,
      'content': content,
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm ghi chú!')),
        );
      }
      _loadNotes();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi thêm ghi chú!')),
        );
      }
    }
  }

  Future<void> _deleteNote(String id) async {
    final success = await FirebaseService.deleteData('notes/$id');

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ghi chú!')),
        );
      }
      _loadNotes();
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ghi chú mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'IT HUTECH',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                hintText: 'Bui Phu Khuyen',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                _addNote(titleController.text, contentController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Ghi chú'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có ghi chú nào\n(Nhấn + để thêm)',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text(note.content),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(note.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== CHAT SCREEN ====================
class ChatMessage {
  final String? id;
  final String text;
  final String oderId;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.text,
    required this.oderId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessage(
      id: id,
      text: json['text'] ?? '',
      oderId: json['oderId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  String get currentUserId => widget.userId;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Tự động refresh mỗi 3 giây để xem tin nhắn mới
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final data = await FirebaseService.getData('chats');

    if (mounted) {
      setState(() {
        isLoading = false;
        if (data != null) {
          messages = data.entries
              .map(
                (e) => ChatMessage.fromJson(
                  e.key,
                  Map<String, dynamic>.from(e.value),
                ),
              )
              .toList();
          // Sắp xếp theo thời gian
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        } else {
          messages = [];
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final success = await FirebaseService.postData('chats', {
      'text': text,
      'oderId': currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (success) {
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Chat Firebase'),
            Text(
              'UID: $currentUserId',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('Chưa có tin nhắn'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.oderId == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Gửi tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
