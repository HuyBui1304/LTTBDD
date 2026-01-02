import 'package:http/http.dart' as http;
import 'dart:convert';

// Model Post
class Post {
  final int? id;
  final String? title;
  final String? body;

  Post({
    required this.id,
    required this.title,
    required this.body,
  });

  // Deserialize: Map(JSON) -> Object
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int?,
      title: json['title'] as String?,
      body: json['body'] as String?,
    );
  }

  // Serialize: Object -> Map(JSON)
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
      };
}

// Model Thing
class Thing {
  final int? id;
  final String? name;
  final Map<String, dynamic>? data;

  Thing({
    required this.id,
    this.name,
    this.data,
  });

  // Deserialize: Map(JSON) -> Object
  factory Thing.fromJson(Map<String, dynamic> json) {
    return Thing(
      id: json['id'] as int?,
      name: json['name'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  // Serialize: Object -> Map(JSON)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'data': data,
      };
}

// ApiService để kết nối với REST API
class ApiService {
  final String baseUrl = 'https://my-json-server.typicode.com/buiphukhuyen/api/posts';

  // Lấy toàn bộ bài viết
  Future<List<Post>> fetchAllPosts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Có lỗi khi tải toàn bộ bài viết');
    }
  }

  // Lấy một bài viết cụ thể theo ID
  Future<Post> fetchPost(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Có lỗi khi tải chi tiết bài viết');
    }
  }

  // Lấy danh sách things (không có limit)
  Future<List<Thing>> fetchThings() async {
    final response = await http.get(Uri.parse('https://api.example.com/v1/things'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Thing.fromJson(json)).toList();
    } else {
      throw Exception('Có lỗi khi tải danh sách things');
    }
  }

  // Lấy danh sách things với limit
  Future<List<Thing>> fetchThingsWithLimit(int limit) async {
    final response = await http.get(Uri.parse('https://api.example.com/v1/things?limit=$limit'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Thing.fromJson(json)).toList();
    } else {
      throw Exception('Có lỗi khi tải danh sách things với limit');
    }
  }
}

// Hàm main để test API - có thể debug trực tiếp trong file này
void main() async {
  final apiService = ApiService();

  try {
    // Test 1: Lấy toàn bộ bài viết
    print('=== Lấy toàn bộ bài viết ===');
    final List<Post> posts = await apiService.fetchAllPosts();
    print('Số lượng bài viết: ${posts.length}');
    for (var post in posts) {
      print('ID: ${post.id}, Title: ${post.title}');
      print('Body: ${post.body}\n');
    }

    // Test 2: Lấy một bài viết cụ thể theo ID
    print('=== Lấy bài viết theo ID = 1 ===');
    final Post post = await apiService.fetchPost(1);
    print('ID: ${post.id}');
    print('Title: ${post.title}');
    print('Body: ${post.body}\n');

    // Test 3: Lấy danh sách things (không có limit)
    print('=== Lấy danh sách things (không có limit) ===');
    final List<Thing> things = await apiService.fetchThings();
    print('Số lượng things: ${things.length}');
    for (var thing in things) {
      print('ID: ${thing.id}, Name: ${thing.name}');
    }

    // Test 4: Lấy danh sách things với limit = 10
    print('\n=== Lấy danh sách things với limit = 10 ===');
    final List<Thing> thingsWithLimit = await apiService.fetchThingsWithLimit(10);
    print('Số lượng things: ${thingsWithLimit.length}');
    for (var thing in thingsWithLimit) {
      print('ID: ${thing.id}, Name: ${thing.name}');
    }
  } catch (e) {
    print('Lỗi: $e');
  }
}

