import 'package:flutter/material.dart';
import 'restAPI.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late Future<List<Post>>
      futurePosts; // Biến lưu trữ Future để lấy danh sách bài viết từ API

  @override
  void initState() {
    super.initState();
    futurePosts =
        ApiService().fetchAllPosts(); // Khởi tạo Future để lấy toàn bộ bài viết
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bài viết'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Post>>(
        future: futurePosts, // Future để lấy dữ liệu từ API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Hiển thị vòng tròn chờ
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // Hiển thị lỗi
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            // Lấy danh sách bài viết
            List<Post> posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length, // Số lượng bài viết
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(posts[index].title ?? ''), // Hiển thị tiêu đề của bài viết
                  subtitle: Text(posts[index].body ?? ''), // Hiển thị nội dung của bài viết
                );
              },
            );
          } else {
            // Trường hợp không có dữ liệu (danh sách rỗng)
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }
        },
      ),
    );
  }
}

