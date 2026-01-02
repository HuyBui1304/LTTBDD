import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cách lưu trữ dữ liệu - Sử dụng các phương thức set
Future<void> saveData() async {
  // Khởi tạo Shared Preferences
  final prefs = await SharedPreferences.getInstance();

  // Lưu trữ giá trị int 10 vào key 'counter'
  await prefs.setInt('counter', 10);

  // Lưu trữ giá trị bool true vào key 'repeat'
  await prefs.setBool('repeat', true);

  // Lưu trữ giá trị double 1.5 vào key 'decimal'
  await prefs.setDouble('decimal', 1.5);

  // Lưu trữ giá trị String Start vào key 'action'
  await prefs.setString('action', 'Start');

  // Lưu trữ danh sách String vào key 'items'
  await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
}

// Cách đọc/xóa dữ liệu - Sử dụng các phương thức get/remove
Future<Map<String, dynamic>> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  // Shared Preferences sẽ tìm kiếm và lấy data với key truyền vào. Nếu không tồn tại giá trị chứa
  // key đó sẽ trả về null
  int? counter = prefs.getInt('counter');
  bool? repeat = prefs.getBool('repeat');
  double? decimal = prefs.getDouble('decimal');
  String? action = prefs.getString('action');
  List<String>? items = prefs.getStringList('items');

  // In kết quả để kiểm tra
  print('Counter: $counter');
  print('Repeat: $repeat');
  print('Decimal: $decimal');
  print('Action: $action');
  print('Items: $items');

  return {
    'counter': counter,
    'repeat': repeat,
    'decimal': decimal,
    'action': action,
    'items': items,
  };
}

Future<void> removeData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('counter'); // Xóa dữ liệu với key 'counter'
  print('Đã xóa key "counter"');
}

// Flutter App với màn hình đăng nhập
void main() {
  runApp(const SharedPreferencesApp());
}

class SharedPreferencesApp extends StatelessWidget {
  const SharedPreferencesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginCheckScreen(),
    );
  }
}

// Màn hình kiểm tra trạng thái đăng nhập
class LoginCheckScreen extends StatefulWidget {
  const LoginCheckScreen({super.key});

  @override
  State<LoginCheckScreen> createState() => _LoginCheckScreenState();
}

class _LoginCheckScreenState extends State<LoginCheckScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Chưa đăng nhập => LoginScreen()
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: () {
        setState(() {
          _isLoggedIn = true;
        });
      });
    }

    // Đã đăng nhập => DashboardScreen()
    return DashboardScreen(onLogout: () {
      setState(() {
        _isLoggedIn = false;
      });
    });
  }
}

// Màn hình đăng nhập
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'huybm.ds@gmail.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      // Lưu thông tin đăng nhập vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);
      await prefs.setString('password', password);

      // Gọi callback để chuyển màn hình
      widget.onLoginSuccess();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình Dashboard (Hồ sơ)
class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DashboardScreen({super.key, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _email;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? 'email@example.com';
      _phone = prefs.getString('phone') ?? '0123456789';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tên người dùng',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(_email ?? 'email@example.com'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Số điện thoại'),
                subtitle: Text(_phone ?? '0123456789'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: 1,
      ),
    );
  }
}

