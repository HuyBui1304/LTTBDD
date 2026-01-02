import 'dart:convert';

// Bước 1: Tạo Model (Object)
class User {
  String name;
  String studentId;
  int age;

  User({required this.name, required this.studentId, required this.age});

  // Phương thức chuyển đổi từ Object Dart sang JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'studentId': studentId,
        'age': age,
      };
}

// Bước 2: Chuyển đổi Object sang JSON
void main() {
  // Tạo đối tượng User
  User user = User(name: 'Bùi Minh Huy', studentId: '2286400009', age: 21);
  
  // Chuyển đổi Object sang JSON string
  String jsonString = jsonEncode(user.toJson());
  
  // In kết quả ra console
  print(jsonString);
  // Output: {"name": "Bùi Minh Huy", "studentId":"2286400009", "age":21}
}

