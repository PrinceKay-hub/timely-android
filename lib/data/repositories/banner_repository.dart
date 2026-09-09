import 'package:booking/data/models/baner_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerRepository {
  final FirebaseFirestore _firestore;
  BannerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<BannerModel>> watchActiveBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc.data()))
            .toList());
  }
}