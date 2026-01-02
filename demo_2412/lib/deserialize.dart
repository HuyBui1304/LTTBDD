import 'dart:convert';

class User {
  final String name;
  final String studentId;
  final int age;

  User({required this.name, required this.studentId, required this.age});

  // Deserialize: Map(JSON) -> Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      studentId: json['studentId'] as String,
      age: json['age'] as int,
    );
  }
}

void main() {
  // Bước 1: Chuỗi JSON nhận từ server (ví dụ)
  const jsonString = '{"name":"Bùi Minh Huy","studentId":"2286400009","age":21}';

  // Bước 2: JSON String -> Map -> Object
  final Map<String, dynamic> userMap = jsonDecode(jsonString);
  final user = User.fromJson(userMap);

  print('Name: ${user.name}, Student ID: ${user.studentId}, Age: ${user.age}');
  // Output: Name: Bùi Minh Huy, Student ID: 2286400009, Age: 21
}

