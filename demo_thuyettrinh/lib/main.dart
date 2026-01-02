import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Cần tạo file này bằng: flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase (nếu chưa được init)
  try {
    // Kiểm tra Firebase đã được khởi tạo chưa
    if (Firebase.apps.isEmpty) {
      // Nếu đã có firebase_options.dart, bỏ comment và dùng:
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      
      // Hoặc khởi tạo với default options
      // Cần có google-services.json (Android) và GoogleService-Info.plist (iOS)
      await Firebase.initializeApp();
    }
  } catch (e) {
    // Nếu lỗi, vẫn chạy app nhưng sẽ hiển thị error screen khi dùng Firestore
    debugPrint('Firebase initialization error: $e');
    debugPrint('App sẽ vẫn chạy nhưng cần setup Firebase để sử dụng Firestore');
  }
  
  runApp(const ProductStoreApp());
}

class ProductStoreApp extends StatelessWidget {
  const ProductStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý sản phẩm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductListScreen(),
    );
  }
}

// ===== MODEL: Product =====
class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String category;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }

  // Create Product from Firestore document
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  // Create a copy with modified fields
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
    );
  }
}

// ===== SERVICE: ProductService để quản lý Firestore =====
class ProductService {
  final String _collection = 'products';

  // Kiểm tra Firebase đã được khởi tạo chưa
  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Lấy Firestore instance (có error handling)
  FirebaseFirestore? get _firestore {
    try {
      if (_isFirebaseInitialized) {
        return FirebaseFirestore.instance;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream để lấy danh sách sản phẩm real-time
  Stream<List<Product>> getProducts() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.error('Firebase chưa được khởi tạo. Vui lòng setup Firebase project trước.');
    }
    
    return firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      throw error;
    });
  }

  // Tìm kiếm sản phẩm theo tên (real-time)
  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) {
      return getProducts();
    }
    
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.error('Firebase chưa được khởi tạo. Vui lòng setup Firebase project trước.');
    }
    
    return firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      throw error;
    });
  }

  // Thêm sản phẩm mới
  Future<void> addProduct(Product product) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Firebase chưa được khởi tạo');
    }
    await firestore.collection(_collection).add(product.toMap());
  }

  // Cập nhật sản phẩm
  Future<void> updateProduct(Product product) async {
    if (product.id == null) return;
    
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Firebase chưa được khởi tạo');
    }
    await firestore
        .collection(_collection)
        .doc(product.id)
        .update(product.toMap());
  }

  // Xóa sản phẩm
  Future<void> deleteProduct(String id) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Firebase chưa được khởi tạo');
    }
    await firestore.collection(_collection).doc(id).delete();
  }
}

// ===== SCREEN: ProductListScreen =====
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hiển thị dialog để thêm/sửa sản phẩm
  Future<void> _showProductDialog({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController =
        TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final quantityController =
        TextEditingController(text: product?.quantity.toString() ?? '');
    final categoryController =
        TextEditingController(text: product?.category ?? '');

    // Biến để quản lý loading state
    bool dialogIsLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Không cho đóng bằng cách tap bên ngoài khi đang xử lý
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogIsLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  TextField(
                    controller: nameController,
                    enabled: !dialogIsLoading,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    enabled: !dialogIsLoading,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    enabled: !dialogIsLoading,
                    decoration: const InputDecoration(
                      labelText: 'Giá (VNĐ) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    enabled: !dialogIsLoading,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    enabled: !dialogIsLoading,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: dialogIsLoading
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: dialogIsLoading
                    ? null
                    : () async {
                        // Validate
                        if (nameController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty ||
                            priceController.text.trim().isEmpty ||
                            quantityController.text.trim().isEmpty ||
                            categoryController.text.trim().isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vui lòng điền đầy đủ thông tin')),
                            );
                          }
                          return;
                        }

                        // Set loading state
                        setDialogState(() {
                          dialogIsLoading = true;
                        });

                        try {
                          final price =
                              double.tryParse(priceController.text.trim()) ?? 0.0;
                          final quantity =
                              int.tryParse(quantityController.text.trim()) ?? 0;

                          if (price <= 0 || quantity < 0) {
                            throw Exception(
                                'Giá phải lớn hơn 0 và số lượng phải >= 0');
                          }

                          final newProduct = Product(
                            id: product?.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            price: price,
                            quantity: quantity,
                            category: categoryController.text.trim(),
                          );

                          // Thực hiện thêm/cập nhật với timeout
                          if (product == null) {
                            await _productService
                                .addProduct(newProduct)
                                .timeout(
                              const Duration(seconds: 10),
                              onTimeout: () {
                                throw Exception(
                                    'Timeout: Không thể kết nối đến Firebase. Vui lòng kiểm tra kết nối mạng.');
                              },
                            );
                          } else {
                            await _productService
                                .updateProduct(newProduct)
                                .timeout(
                              const Duration(seconds: 10),
                              onTimeout: () {
                                throw Exception(
                                    'Timeout: Không thể kết nối đến Firebase. Vui lòng kiểm tra kết nối mạng.');
                              },
                            );
                          }

                          // Đóng dialog trước khi hiển thị SnackBar
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          // Hiển thị thông báo thành công
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(product == null
                                    ? 'Đã thêm sản phẩm thành công'
                                    : 'Đã cập nhật sản phẩm thành công'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          // Reset loading state nếu có lỗi
                          setDialogState(() {
                            dialogIsLoading = false;
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                child: dialogIsLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(product == null ? 'Thêm' : 'Cập nhật'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    categoryController.dispose();
  }

  // Xóa sản phẩm với xác nhận
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && product.id != null) {
      try {
        await _productService.deleteProduct(product.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sản phẩm')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nguyễn Ngọc Quỳnh Anh 2286400908'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
          children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Product list với StreamBuilder để đồng bộ real-time
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _searchQuery.isEmpty
                  ? _productService.getProducts()
                  : _productService.searchProducts(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Lỗi kết nối Firebase',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Vui lòng setup Firebase:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('1. Tạo Firebase project trên Firebase Console'),
                          const Text('2. Chạy: flutterfire configure'),
                          const Text('3. Hoặc thêm google-services.json (Android)'),
                          const Text('    và GoogleService-Info.plist (iOS)'),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Vui lòng xem hướng dẫn trong code comments'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            child: const Text('Đã hiểu'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Chưa có sản phẩm nào'
                              : 'Không tìm thấy sản phẩm',
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Mô tả: ${product.description}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Danh mục: ${product.category}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Giá: ${_formatPrice(product.price)} VNĐ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SL: ${product.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: product.quantity > 0
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () => _showProductDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Format giá tiền
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}
