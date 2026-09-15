import 'dart:io';

import 'package:booking/data/models/product_model.dart';
import 'package:booking/data/repositories/shop_api_services.dart';
import 'package:booking/data/repositories/shop_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


part 'sell_state.dart';

class SellCubit extends Cubit<SellState> {
  final ShopApiService _api;
  final ShopRepository _repo;
  final ImagePicker _picker;

  SellCubit({
    String? productId,
    ShopApiService? api,
    ShopRepository? repository,
    ImagePicker? picker,
  })  : _api = api ?? ShopApiService(),
        _repo = repository ?? ShopRepository(),
        _picker = picker ?? ImagePicker(),
        super(SellState(productId: productId)) {
    if (productId != null) {
      loadForEdit(productId);
    }
  }

  Future<void> loadForEdit(String productId) async {
    emit(state.copyWith(loadStatus: SellLoadStatus.loading));
    try {
      final product = await _repo.fetchProduct(productId);
      if (product == null) {
        emit(state.copyWith(loadStatus: SellLoadStatus.error));
        return;
      }
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && product.sellerId != currentUid) {
        emit(state.copyWith(loadStatus: SellLoadStatus.error));
        return;
      }

      emit(state.copyWith(
        loadStatus: SellLoadStatus.loaded,
        name: product.name,
        description: product.description,
        price: product.price.toString(),
        category: product.category,
        tags: product.tags,
        existingImages: product.images,
        isDelivery: product.isDelivery,
        useCall: product.contact.isNotEmpty,
        callNumber: product.contact,
        selectedLocation: product.location != null
            ? SelectedLocation(
                region: product.location!.region,
                district: product.location!.district,
              )
            : null,
        landmark: product.location?.landmark ?? '',
      ));
    } catch (_) {
      emit(state.copyWith(loadStatus: SellLoadStatus.error));
    }
  }

  // ─── Images ─────────────────────────────────────────────────────────
  Future<void> pickImages() async {
    final remaining = kMaxImages - state.totalImageCount;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    final newEntries = picked
        .map((x) => PickedImage(
              id: '${DateTime.now().microsecondsSinceEpoch}-${x.path}',
              path: x.path,
              processing: true,
            ))
        .toList();

    emit(state.copyWith(
      images: [...state.images, ...newEntries]
          .take(kMaxImages - state.existingImages.length)
          .toList(),
    ));

    for (final entry in newEntries) {
      _compressImage(entry);
    }
  }

  Future<void> _compressImage(PickedImage entry) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${entry.id}.webp',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        entry.path,
        targetPath,
        minWidth: 1080,
        quality: 70,
        format: CompressFormat.webp,
      );

      if (result == null) throw Exception('Compression returned null');

      final updated = state.images
          .map((img) => img.id == entry.id
              ? img.copyWith(path: result.path, processing: false)
              : img)
          .toList();
      emit(state.copyWith(images: updated));
    } catch (_) {
      emit(state.copyWith(
        images: state.images.where((img) => img.id != entry.id).toList(),
        submitError: "One of your photos couldn't be processed. Try a different one.",
      ));
    }
  }

  void removeImage(String id) {
    emit(state.copyWith(images: state.images.where((i) => i.id != id).toList()));
  }

  void removeExistingImage(String url) {
    emit(state.copyWith(
      existingImages: state.existingImages.where((u) => u != url).toList(),
    ));
  }

  // ─── Fields ─────────────────────────────────────────────────────────
  void setName(String v) => emit(state.copyWith(name: v));
  void setDescription(String v) => emit(state.copyWith(description: v));
  void setPrice(String v) => emit(state.copyWith(price: v));
  void setCategory(ProductCategory c) => emit(state.copyWith(category: c));
  void setTagInput(String v) => emit(state.copyWith(tagInput: v));
  void setLandmark(String v) => emit(state.copyWith(landmark: v));
  void setSelectedLocation(SelectedLocation loc) =>
      emit(state.copyWith(selectedLocation: loc));
  void clearSelectedLocation() => emit(state.copyWith(clearLocation: true));
  void setUseCall(bool v) => emit(state.copyWith(useCall: v));
  void setCallNumber(String v) => emit(state.copyWith(callNumber: v));
  void setIsDelivery(bool v) => emit(state.copyWith(isDelivery: v));

  void addTag() {
    final cleaned = state.tagInput.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    if (state.tags.contains(cleaned)) {
      emit(state.copyWith(tagInput: ''));
      return;
    }
    if (state.tags.length >= kMaxTags) return;
    emit(state.copyWith(tags: [...state.tags, cleaned], tagInput: ''));
  }

  void removeTag(String tag) {
    emit(state.copyWith(tags: state.tags.where((t) => t != tag).toList()));
  }

  // ─── Validation ─────────────────────────────────────────────────────
  String? validate() {
    if (state.totalImageCount == 0) return 'Add at least one photo.';
    if (state.images.any((i) => i.processing)) {
      return 'Hang on — your photos are still processing.';
    }
    if (state.name.trim().isEmpty) return 'Enter a product name.';
    final price = double.tryParse(state.price);
    if (price == null || price <= 0) return 'Enter a valid price.';
    if (state.category == null) return 'Choose a category.';
    if (state.useCall && state.callNumber.trim().isEmpty) {
      return 'Enter a Call number.';
    }
    if (state.selectedLocation == null) return 'Select a location';
    if (state.landmark.trim().isEmpty) return 'Enter nearest landmark';
    return null;
  }

  // ─── Submit ─────────────────────────────────────────────────────────
  Future<bool> submit(String displayName) async {
    final error = validate();
    if (error != null) {
      emit(state.copyWith(submitError: error));
      return false;
    }

    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      var newImageKeys = <String>[];
      if (state.images.isNotEmpty) {
        final uploads = await _api.getUploadUrls(
          List.filled(state.images.length, 'image/webp'),
        );
        await Future.wait([
          for (var i = 0; i < uploads.length; i++)
            _api.uploadFileToB2(
              uploads[i].uploadUrl,
              File(state.images[i].path),
              uploads[i].contentType,
            ),
        ]);
        newImageKeys = uploads.map((u) => u.key).toList();
      }

      final contact = state.useCall ? state.callNumber.trim() : '';
      final loc = state.selectedLocation!;
      final location = ProductLocation(
        region: loc.region,
        district: loc.district,
        landmark: state.landmark.trim(),
      );

      if (state.isEditMode) {
        await _api.updateProduct(UpdateProductInput(
          productId: state.productId!,
          name: state.name.trim(),
          description: state.description.trim(),
          price: double.parse(state.price),
          category: state.category!.id,
          tags: state.tags,
          images: state.existingImages,
          newImageKeys: newImageKeys,
          contact: contact,
          isDelivery: state.isDelivery,
          location: location,
        ));
      } else {
        await _api.createProduct(CreateProductInput(
          name: state.name.trim(),
          description: state.description.trim(),
          price: double.parse(state.price),
          category: state.category!.id,
          tags: state.tags,
          imageKeys: newImageKeys,
          contact: contact,
          isDelivery: state.isDelivery,
          location: location,
          sellerName: displayName,
        ));
      }

      emit(state.copyWith(submitting: false, submitted: true));
      return true;
    } catch (_) {
      emit(state.copyWith(
        submitting: false,
        submitError: state.isEditMode
            ? "Couldn't save your changes. Try again."
            : "Couldn't publish your listing. Try again.",
      ));
      return false;
    }
  }
}