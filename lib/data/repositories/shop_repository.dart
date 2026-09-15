import 'package:booking/data/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


const int kProductsPageSize = 20;
const int kSearchCatalogLimit = 150;
const int kRelatedProductsLimit = 11;

class ShopRepository {
  final FirebaseFirestore _db;

  ShopRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Paginated feed for the Shop tab, optionally filtered by category.
  Future<(List<Product> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc)>
      fetchProductsPage({
    ProductCategory? category,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kProductsPageSize,
  }) async {
    Query<Map<String, dynamic>> q = _products
        .where('status', isEqualTo: ProductStatus.active.id)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      q = q.where('category', isEqualTo: category.id);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    q = q.limit(limit);

    final snap = await q.get();
    final items = snap.docs.map(Product.fromDoc).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (items, lastDoc);
  }

  /// Full active-product catalog used client-side by the search screen.
  Future<List<Product>> fetchSearchCatalog({int limit = kSearchCatalogLimit}) async {
    final snap = await _products
        .where('status', isEqualTo: ProductStatus.active.id)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<Product?> fetchProduct(String productId) async {
    final snap = await _products.doc(productId).get();
    if (!snap.exists) return null;
    return Product.fromDoc(snap);
  }

  Future<void> incrementViewCount(String productId) {
    return _products.doc(productId).update({'viewCount': FieldValue.increment(1)});
  }

  Future<List<Product>> fetchRelatedProducts({
    required ProductCategory category,
    required String excludeProductId,
    int limit = kRelatedProductsLimit,
  }) async {
    final snap = await _products
        .where('category', isEqualTo: category.id)
        .where('status', isEqualTo: ProductStatus.active.id)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map(Product.fromDoc)
        .where((p) => p.productId != excludeProductId)
        .take(limit - 1)
        .toList();
  }

  Future<List<Product>> fetchMyListings(String uid) async {
    final snap = await _products
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<void> setStatus(String productId, ProductStatus status) {
    return _products.doc(productId).update({'status': status.id});
  }

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}