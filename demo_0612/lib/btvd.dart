import 'package:flutter/material.dart';

void main() {
  runApp(const HutechCampusApp());
}

class HutechCampusApp extends StatelessWidget {
  const HutechCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus tại HUTECH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        DetailsScreen.routeName: (context) => const DetailsScreen(),
      },
    );
  }
}

class Campus {
  final String name;
  final String address;
  final String description;
  final Color color;
  final String imagePath;

  Campus({
    required this.name,
    required this.address,
    required this.description,
    required this.color,
    required this.imagePath,
  });
}

final List<Campus> campuses = [
  Campus(
    name: 'Saigon Campus',
    address: '475A Điện Biên Phủ, P.25, Q.Bình Thạnh, TP.HCM',
    description:
        'Trụ sở chính của HUTECH, bao gồm nhiều khoa, phòng ban, hội trường lớn.',
    color: Colors.red,
    imagePath: 'assets/A.webp', 
  ),
  Campus(
    name: 'Ung Van Khiem Campus',
    address: '31/36 Ung Văn Khiêm, P.25, Q.Bình Thạnh, TP.HCM',
    description:
        'Khu học tập với nhiều phòng thực hành và giảng đường hiện đại.',
    color: Colors.green,
    imagePath: 'assets/U.webp', 
  ),
  Campus(
    name: 'Thu Duc Campus',
    address: 'Khu Công nghệ cao TP.HCM, Xa lộ Hà Nội, TP.Thủ Đức',
    description:
        'Khuôn viên rộng, nhiều không gian xanh, dành cho các ngành kỹ thuật – công nghệ.',
    color: Colors.blue,
    imagePath: 'assets/E.webp', 
  ),
  Campus(
    name: 'Hitech Park Campus',
    address: 'Công viên Phần mềm Quang Trung, Q.12, TP.HCM',
    description:
        'Tập trung các phòng lab, trung tâm nghiên cứu và liên kết doanh nghiệp.',
    color: Colors.amber,
    imagePath: 'assets/R.jpeg', 
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDetailsWithPush(BuildContext context, Campus campus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(campus: campus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các cơ sở HUTECH'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: campuses.length,
        itemBuilder: (context, index) {
          final campus = campuses[index];

          return Card(
            color: campus.color,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                campus.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                campus.address,
                style: const TextStyle(color: Colors.white),
              ),
              trailing:
                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _openDetailsWithPush(context, campus),
            ),
          );
        },
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  static const String routeName = '/details';

  final Campus? campus;

  const DetailsScreen({super.key, this.campus});

  Campus _resolveCampus(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Campus) {
      return args;
    }
    if (campus != null) {
      return campus!;
    }
    return campuses.first;
  }

  void _backNormally(BuildContext context) {
    Navigator.pop(context);
  }

  void _backToHomeWithReplacement(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }

  void _backToHomeClearHistory(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
    );
  }

  void _openAnotherCampusWithReplacement(BuildContext context) {
    final anotherCampus = campuses.last;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(campus: anotherCampus),
      ),
    );
  }

  void _goHomeWithPushAndRemoveUntil(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final campusData = _resolveCampus(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(campusData.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  campusData.imagePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              campusData.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campusData.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Thông tin chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              campusData.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Điều hướng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _backNormally(context),
                  child: const Text('Quay lại màn trước'),
                ),
                ElevatedButton(
                  onPressed: () => _openAnotherCampusWithReplacement(context),
                  child: const Text('Xem cơ sở khác'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}