import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadServiceImage({
    required String imageFile,
    required String userId,
  }) async {
    try {
      // Generate unique filename
      final String fileName = _uuid.v4();
      final String filePath = 'service_images/$userId/$fileName.jpg';
      
      // Upload file
      final Reference ref = _storage.ref().child(filePath);
      final UploadTask uploadTask = ref.putFile(
        File(imageFile),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages({
    required List<String> imageFiles,
    required String userId,
  }) async {
    try {
      final List<String> imageUrls = [];
      
      for (final imageFile in imageFiles) {
        final url = await uploadServiceImage(
          imageFile: imageFile,
          userId: userId,
        );
        imageUrls.add(url);
      }
      
      return imageUrls;
    } catch (e) {
      print('Error uploading multiple images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<void> deleteImage(String imageUrl, String serviceId) async {
    try {

      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();

       await _firestore
          .collection('services').doc(serviceId).update({
            'images': FieldValue.arrayRemove([imageUrl])
           })
           .then((_) => print('Image URL removed from Firestore'))
           .catchError((error) => print('Error removing image URL: $error'));

    } catch (e) {
      print('Error deleting image: $e');
      // Don't throw, just log the error
    }
  }
}