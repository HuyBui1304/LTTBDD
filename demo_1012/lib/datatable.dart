import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DataTable Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // nền trắng
      ),
      home: const LanguageTablePage(),
    );
  }
}

// ----------------- MODEL -----------------

class LanguageInfo {
  LanguageInfo({
    required this.year,
    required this.lang,
    required this.colors,
    this.favorite = false,
  });

  int year;
  String lang;
  List<Color> colors;
  bool favorite;
}

// ----------------- MÀN HÌNH CHÍNH -----------------

class LanguageTablePage extends StatefulWidget {
  const LanguageTablePage({super.key});

  @override
  State<LanguageTablePage> createState() => _LanguageTablePageState();
}

class _LanguageTablePageState extends State<LanguageTablePage> {
  int? _sortColumnIndex = 1; // cột Year
  bool _sortAscending = true;

  final List<LanguageInfo> _rows = [
    LanguageInfo(
      year: 2018,
      lang: 'Dart',
      colors: [Colors.grey.shade700],
      favorite: true,
    ),
    LanguageInfo(
      year: 2015,
      lang: 'Rust',
      colors: [Colors.lightBlue],
    ),
    LanguageInfo(
      year: 2009,
      lang: 'Go',
      colors: [Colors.black, Colors.white],
    ),
    LanguageInfo(
      year: 1998,
      lang: 'PHP',
      colors: [Colors.lightBlue],
    ),
    LanguageInfo(
      year: 1992,
      lang: 'Java',
      colors: [Colors.black, Colors.red],
    ),
  ];

  // sort đơn giản theo năm để tránh lỗi kiểu trả về
  void _sortByYear(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _rows.sort((a, b) {
        if (ascending) {
          return a.year.compareTo(b.year);
        } else {
          return b.year.compareTo(a.year);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bùi Minh Huy 2286400009'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // nếu bảng rộng thì kéo ngang
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              const DataColumn(
                label: SizedBox(width: 40), // cột màu (không tiêu đề)
              ),
              DataColumn(
                label: const Text('↑Year'),
                numeric: true, // cột số sẽ tự căn phải
                onSort: _sortByYear,
              ),
              const DataColumn(
                label: Text('Lang.'),
              ),
              const DataColumn(
                label: Text('Favorite'),
              ),
            ],
            rows: _rows.map((item) {
              return DataRow(
                // có thể thêm selected: true nếu muốn đánh dấu hàng được chọn
                cells: [
                  // cột màu
                  DataCell(
                    Row(
                      children: item.colors
                          .map(
                            (c) => Container(
                              margin: const EdgeInsets.only(right: 2),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c == Colors.white ? null : c,
                                border: Border.all(color: Colors.black87),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // cột năm
                  DataCell(
                    Text(
                      item.year.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),

                  // cột ngôn ngữ
                  DataCell(
                    Text(
                      item.lang,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // cột Favorite (icon heart có thể bấm)
                  DataCell(
                    IconButton(
                      icon: Icon(
                        item.favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          item.favorite = !item.favorite;
                        });
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}