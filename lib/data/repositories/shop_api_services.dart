import 'dart:io';
import 'dart:typed_data';

import 'package:booking/data/models/product_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;


class UploadResult {
  final String key;
  final String uploadUrl;
  final String contentType;

  UploadResult({
    required this.key,
    required this.uploadUrl,
    required this.contentType,
  });

  factory UploadResult.fromMap(Map<dynamic, dynamic> map) {
    return UploadResult(
      key: map['key'] as String,
      uploadUrl: map['uploadUrl'] as String,
      contentType: map['contentType'] as String,
    );
  }
}

class CreateProductInput {
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> tags;
  final List<String> imageKeys;
  final String contact;
  final bool isDelivery;
  final ProductLocation location;
  final String sellerName;

  CreateProductInput({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.tags,
    required this.imageKeys,
    required this.contact,
    required this.isDelivery,
    required this.location,
    required this.sellerName,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'tags': tags,
        'imageKeys': imageKeys,
        'contact': contact,
        'isDelivery': isDelivery,
        'location': location.toMap(),
        'sellerName': sellerName,
      };
}

class UpdateProductInput {
  final String productId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> tags;
  final List<String> images;
  final List<String> newImageKeys;
  final String contact;
  final bool isDelivery;
  final ProductLocation location;

  UpdateProductInput({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.tags,
    required this.images,
    required this.newImageKeys,
    required this.contact,
    required this.isDelivery,
    required this.location,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'tags': tags,
        'images': images,
        'newImageKeys': newImageKeys,
        'contact': contact,
        'isDelivery': isDelivery,
        'location': location.toMap(),
      };
}

class ProductMutationResult {
  final String productId;
  final String thumbnailUrl;

  ProductMutationResult({required this.productId, required this.thumbnailUrl});
}

class ShopApiService {
  final FirebaseFunctions _functions;
  final http.Client _httpClient;

  ShopApiService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _httpClient = httpClient ?? http.Client();

  Future<List<UploadResult>> getUploadUrls(List<String> contentTypes) async {
    final callable = _functions.httpsCallable('getUploadUrl');
    final res = await callable.call<Map<String, dynamic>>({
      'files': contentTypes.map((t) => {'contentType': t}).toList(),
    });
    final uploads = (res.data['uploads'] as List)
        .map((e) => UploadResult.fromMap(e as Map))
        .toList();
    return uploads;
  }

  /// Uploads raw [bytes] (already compressed) to the pre-signed B2 URL.
  Future<void> uploadBytesToB2(
    String uploadUrl,
    Uint8List bytes,
    String contentType,
  ) async {
    final res = await _httpClient.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Upload failed with status ${res.statusCode}');
    }
  }

  Future<void> uploadFileToB2(
    String uploadUrl,
    File file,
    String contentType,
  ) async {
    final bytes = await file.readAsBytes();
    await uploadBytesToB2(uploadUrl, bytes, contentType);
  }

  Future<ProductMutationResult> createProduct(CreateProductInput input) async {
    final callable = _functions.httpsCallable('createProduct');
    final res = await callable.call<Map<String, dynamic>>(input.toMap());
    return ProductMutationResult(
      productId: res.data['productId'] as String,
      thumbnailUrl: res.data['thumbnailUrl'] as String? ?? '',
    );
  }

  Future<void> deleteProduct(String productId) async {
    final callable = _functions.httpsCallable('deleteProduct');
    await callable.call({'productId': productId});
  }

  Future<ProductMutationResult> updateProduct(UpdateProductInput input) async {
    final callable = _functions.httpsCallable('updateProduct');
    final res = await callable.call<Map<String, dynamic>>(input.toMap());
    return ProductMutationResult(
      productId: res.data['productId'] as String,
      thumbnailUrl: res.data['thumbnailUrl'] as String? ?? '',
    );
  }
}