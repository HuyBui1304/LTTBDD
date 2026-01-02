import 'package:flutter/material.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoScreen(),
    );
  }
}

// ===== DATA sinh viên (đưa ra ngoài để hot reload hoạt động) =====
List<Map<String, String>> getStudentsData() {
  return [
    {
      'name': 'Bùi Minh Huy',
      'id': '2286400009',
      'class': '22DKHA1',
      'phone': '0901 234 567',
      'email': 'huy.bm@hutech.edu.vn',
    },
    {
      'name': 'Trần Lê Vân',
      'id': '2286400042',
      'class': '22DKHA1',
      'phone': '0902 345 678',
      'email': 'van.tl@hutech.edu.vn',
    },
    {
      'name': 'Nguyễn Thị Thanh Tâm',
      'id': '2286400028',
      'class': '22DKHA1',
      'phone': '0903 456 789',
      'email': 'tam.ntt@hutech.edu.vn',
    },
  ];
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // ===== STATE cho card tương tác =====
  int counter = 0;
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('demo nhóm 1'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================================================
          // ==================================================
          ...getStudentsData().asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Sinh viên ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text('Họ tên: ${student['name']}'),
                      Text('MSSV: ${student['id']}'),
                      Text('Lớp: ${student['class']}'),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Thông tin liên hệ'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'SĐT: ${student['phone']}'),
                                      const SizedBox(height: 6),
                                      Text(
                                          'Email: ${student['email']}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Xem chi tiết'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ==================================================
          // ==================================================
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tương tác người dùng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Giá trị hiện tại: $counter',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            counter++;
                          });
                        },
                        child: const Text('+'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (counter > 0) counter--;
                          });
                        },
                        child: const Text('-'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOn ? 'Trạng thái: Đang bật' : 'Trạng thái: Đang tắt',
                      ),
                      Switch(
                        value: isOn,
                        onChanged: (value) {
                          setState(() {
                            isOn = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}