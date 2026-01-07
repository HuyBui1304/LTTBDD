import '../database/database_helper.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../models/quiz.dart';
import '../services/auth_service.dart';

class SeedDataService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> seedData() async {
    // Seed users first
    await seedUsers();

    // Check if data already exists
    final existingTopics = await _dbHelper.getAllTopics();
    if (existingTopics.isNotEmpty) {
      return; // Data already exists
    }

    // Seed topics first
    final topics = _getSampleTopics();
    final topicIds = <int>[];
    for (final topic in topics) {
      final id = await _dbHelper.insertTopic(topic);
      topicIds.add(id);
    }

    // Seed questions
    final questions = _getSampleQuestions(topicIds);
    for (final question in questions) {
      await _dbHelper.insertQuestion(question);
    }

    // Seed quizzes
    final quizzes = _getSampleQuizzes(topicIds);
    for (final quiz in quizzes) {
      await _dbHelper.insertQuiz(quiz);
    }
  }

  Future<void> seedUsers() async {
    final authService = AuthService();

    // Create admin user
    final adminUser = await _dbHelper.getUserByEmail('admin@gmail.com');
    if (adminUser == null) {
      try {
        await authService.register(
          'admin@gmail.com',
          '123456',
          'Administrator',
          role: 'admin',
        );
      } catch (e) {
        // User already exists or error
      }
    }

    // Create regular user
    final regularUser = await _dbHelper.getUserByEmail('user@gmail.com');
    if (regularUser == null) {
      try {
        await authService.register(
          'user@gmail.com',
          '123456',
          'Test User',
          role: 'user',
        );
      } catch (e) {
        // User already exists or error
      }
    }
  }

  Future<void> clearAndReseed() async {
    final db = await _dbHelper.database;
    await db.delete('quiz_results');
    await db.delete('user_progress');
    await db.delete('questions');
    await db.delete('quizzes');
    await db.delete('topics');
    await db.delete('audit_log');
    // Don't delete users, just reseed data
    await seedData();
  }

  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('quiz_results');
    await db.delete('user_progress');
    await db.delete('questions');
    await db.delete('quizzes');
    await db.delete('topics');
    await db.delete('audit_log');
    await db.delete('users');
    await seedData();
  }

  List<Topic> _getSampleTopics() {
    final now = DateTime.now();
    return [
      Topic(
        name: 'Lập trình cơ bản',
        description: 'Các khái niệm cơ bản về lập trình',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Topic(
        name: 'Cơ sở dữ liệu',
        description: 'SQL, Database design, Normalization',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Topic(
        name: 'Lập trình hướng đối tượng',
        description: 'OOP concepts, Classes, Inheritance, Polymorphism',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      Topic(
        name: 'Cấu trúc dữ liệu và giải thuật',
        description: 'Data structures, Algorithms, Complexity',
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      Topic(
        name: 'Mạng máy tính',
        description: 'Network protocols, TCP/IP, OSI model',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  List<Question> _getSampleQuestions(List<int> topicIds) {
    final now = DateTime.now();
    if (topicIds.length < 5) return [];

    return [
      // Lập trình cơ bản
      Question(
        questionText: 'Ngôn ngữ lập trình nào được sử dụng để phát triển ứng dụng Flutter?',
        options: ['Java', 'Dart', 'Python', 'JavaScript'],
        correctAnswerIndex: 1,
        topicId: topicIds[0],
        explanation: 'Flutter sử dụng ngôn ngữ Dart do Google phát triển.',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Question(
        questionText: 'Biến nào sau đây là biến toàn cục?',
        options: ['var', 'final', 'const', 'static'],
        correctAnswerIndex: 3,
        topicId: topicIds[0],
        explanation: 'Từ khóa static được dùng để khai báo biến toàn cục trong class.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 29)),
      ),
      // Cơ sở dữ liệu
      Question(
        questionText: 'SQL là viết tắt của gì?',
        options: ['Structured Query Language', 'Simple Query Language', 'Standard Query Language', 'System Query Language'],
        correctAnswerIndex: 0,
        topicId: topicIds[1],
        explanation: 'SQL là Structured Query Language - ngôn ngữ truy vấn có cấu trúc.',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Question(
        questionText: 'Khóa chính (Primary Key) có thể chứa giá trị NULL không?',
        options: ['Có', 'Không', 'Tùy thuộc vào DBMS', 'Chỉ trong một số trường hợp'],
        correctAnswerIndex: 1,
        topicId: topicIds[1],
        explanation: 'Primary Key không thể chứa giá trị NULL và phải là duy nhất.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 27)),
      ),
      Question(
        questionText: 'Dạng chuẩn nào loại bỏ sự phụ thuộc bắc cầu?',
        options: ['1NF', '2NF', '3NF', 'BCNF'],
        correctAnswerIndex: 2,
        topicId: topicIds[1],
        explanation: '3NF (Third Normal Form) loại bỏ sự phụ thuộc bắc cầu.',
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      // OOP
      Question(
        questionText: 'Tính chất nào cho phép một đối tượng có nhiều hình thái?',
        options: ['Encapsulation', 'Inheritance', 'Polymorphism', 'Abstraction'],
        correctAnswerIndex: 2,
        topicId: topicIds[2],
        explanation: 'Polymorphism (Đa hình) cho phép một đối tượng có nhiều hình thái khác nhau.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      Question(
        questionText: 'Lớp trừu tượng (Abstract class) có thể được khởi tạo trực tiếp không?',
        options: ['Có', 'Không', 'Tùy thuộc vào ngôn ngữ', 'Chỉ trong một số trường hợp'],
        correctAnswerIndex: 1,
        topicId: topicIds[2],
        explanation: 'Abstract class không thể được khởi tạo trực tiếp, phải thông qua lớp con.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 24)),
      ),
      // Cấu trúc dữ liệu
      Question(
        questionText: 'Độ phức tạp thời gian của thuật toán tìm kiếm nhị phân là?',
        options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(n²)'],
        correctAnswerIndex: 1,
        topicId: topicIds[3],
        explanation: 'Binary search có độ phức tạp O(log n) vì mỗi bước giảm một nửa không gian tìm kiếm.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      Question(
        questionText: 'Cấu trúc dữ liệu nào hoạt động theo nguyên tắc LIFO?',
        options: ['Queue', 'Stack', 'Tree', 'Graph'],
        correctAnswerIndex: 1,
        topicId: topicIds[3],
        explanation: 'Stack (Ngăn xếp) hoạt động theo nguyên tắc LIFO (Last In First Out).',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      // Mạng máy tính
      Question(
        questionText: 'Giao thức nào được sử dụng để truyền email?',
        options: ['HTTP', 'FTP', 'SMTP', 'TCP'],
        correctAnswerIndex: 2,
        topicId: topicIds[4],
        explanation: 'SMTP (Simple Mail Transfer Protocol) được sử dụng để gửi email.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Question(
        questionText: 'Port mặc định của HTTP là?',
        options: ['80', '443', '21', '25'],
        correctAnswerIndex: 0,
        topicId: topicIds[4],
        explanation: 'Port 80 là port mặc định của HTTP, port 443 là của HTTPS.',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 19)),
      ),
      // Thêm nhiều câu hỏi hơn để test
      // Lập trình cơ bản - thêm
      Question(
        questionText: 'Hàm main() trong Dart có kiểu trả về là gì?',
        options: ['void', 'int', 'String', 'dynamic'],
        correctAnswerIndex: 0,
        topicId: topicIds[0],
        explanation: 'Hàm main() trong Dart có kiểu trả về void.',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      Question(
        questionText: 'Từ khóa nào dùng để khai báo biến không thể thay đổi giá trị?',
        options: ['var', 'final', 'const', 'static'],
        correctAnswerIndex: 2,
        topicId: topicIds[0],
        explanation: 'const dùng để khai báo biến hằng số, không thể thay đổi giá trị.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 17)),
      ),
      // Cơ sở dữ liệu - thêm
      Question(
        questionText: 'Câu lệnh SQL nào dùng để thêm dữ liệu vào bảng?',
        options: ['INSERT', 'UPDATE', 'DELETE', 'SELECT'],
        correctAnswerIndex: 0,
        topicId: topicIds[1],
        explanation: 'INSERT dùng để thêm dữ liệu mới vào bảng.',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      Question(
        questionText: 'Khóa ngoại (Foreign Key) dùng để làm gì?',
        options: ['Đảm bảo tính duy nhất', 'Liên kết giữa các bảng', 'Tăng tốc độ truy vấn', 'Mã hóa dữ liệu'],
        correctAnswerIndex: 1,
        topicId: topicIds[1],
        explanation: 'Foreign Key dùng để liên kết giữa các bảng và đảm bảo tính toàn vẹn dữ liệu.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      // OOP - thêm
      Question(
        questionText: 'Tính đóng gói (Encapsulation) là gì?',
        options: ['Ẩn thông tin chi tiết', 'Kế thừa từ lớp cha', 'Có nhiều hình thái', 'Trừu tượng hóa'],
        correctAnswerIndex: 0,
        topicId: topicIds[2],
        explanation: 'Encapsulation là tính đóng gói, ẩn thông tin chi tiết bên trong và chỉ expose những gì cần thiết.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      Question(
        questionText: 'Interface khác với Abstract class như thế nào?',
        options: ['Interface không có implementation', 'Interface có thể khởi tạo', 'Interface không hỗ trợ đa kế thừa', 'Không có sự khác biệt'],
        correctAnswerIndex: 0,
        topicId: topicIds[2],
        explanation: 'Interface chỉ định nghĩa contract, không có implementation, trong khi Abstract class có thể có implementation.',
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 13)),
      ),
      // Cấu trúc dữ liệu - thêm
      Question(
        questionText: 'Cấu trúc dữ liệu nào hoạt động theo nguyên tắc FIFO?',
        options: ['Stack', 'Queue', 'Tree', 'Graph'],
        correctAnswerIndex: 1,
        topicId: topicIds[3],
        explanation: 'Queue (Hàng đợi) hoạt động theo nguyên tắc FIFO (First In First Out).',
        difficulty: 1,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Question(
        questionText: 'Độ phức tạp thời gian của thuật toán sắp xếp nhanh (Quick Sort) trong trường hợp tốt nhất là?',
        options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'],
        correctAnswerIndex: 1,
        topicId: topicIds[3],
        explanation: 'Quick Sort có độ phức tạp O(n log n) trong trường hợp tốt nhất và trung bình.',
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      // Mạng máy tính - thêm
      Question(
        questionText: 'TCP là viết tắt của gì?',
        options: ['Transmission Control Protocol', 'Transfer Control Protocol', 'Transport Control Protocol', 'Transmission Communication Protocol'],
        correctAnswerIndex: 0,
        topicId: topicIds[4],
        explanation: 'TCP là Transmission Control Protocol - giao thức điều khiển truyền tải.',
        difficulty: 2,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Question(
        questionText: 'Lớp nào trong mô hình OSI chịu trách nhiệm định tuyến?',
        options: ['Lớp 2 (Data Link)', 'Lớp 3 (Network)', 'Lớp 4 (Transport)', 'Lớp 5 (Session)'],
        correctAnswerIndex: 1,
        topicId: topicIds[4],
        explanation: 'Lớp 3 (Network) trong mô hình OSI chịu trách nhiệm định tuyến và địa chỉ hóa logic.',
        difficulty: 3,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
    ];
  }

  List<Quiz> _getSampleQuizzes(List<int> topicIds) {
    final now = DateTime.now();
    if (topicIds.length < 5) return [];

    return [
      Quiz(
        title: 'Kiểm tra nhanh - Lập trình cơ bản',
        description: 'Bài kiểm tra 10 câu về lập trình cơ bản',
        timeLimit: 15,
        questionCount: 10,
        topicIds: [topicIds[0]],
        mode: 'random',
        shuffleQuestions: true,
        showResultImmediately: false,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Quiz(
        title: 'Thi thử - Cơ sở dữ liệu',
        description: 'Đề thi 20 câu về SQL và Database',
        timeLimit: 30,
        questionCount: 20,
        topicIds: [topicIds[1]],
        mode: 'random',
        shuffleQuestions: true,
        showResultImmediately: false,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Quiz(
        title: 'Luyện tập - OOP',
        description: 'Luyện tập các khái niệm OOP',
        questionCount: 15,
        topicIds: [topicIds[2]],
        mode: 'practice',
        shuffleQuestions: true,
        showResultImmediately: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Quiz(
        title: 'Thi tổng hợp',
        description: 'Đề thi tổng hợp tất cả các chủ đề',
        timeLimit: 60,
        questionCount: 30,
        topicIds: topicIds,
        mode: 'random',
        shuffleQuestions: true,
        showResultImmediately: false,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Quiz(
        title: 'Luyện tập - Cấu trúc dữ liệu',
        description: 'Luyện tập các khái niệm về cấu trúc dữ liệu và giải thuật',
        questionCount: 10,
        topicIds: [topicIds[3]],
        mode: 'practice',
        shuffleQuestions: true,
        showResultImmediately: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Quiz(
        title: 'Kiểm tra - Mạng máy tính',
        description: 'Bài kiểm tra về mạng máy tính và các giao thức',
        timeLimit: 20,
        questionCount: 15,
        topicIds: [topicIds[4]],
        mode: 'random',
        shuffleQuestions: true,
        showResultImmediately: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
