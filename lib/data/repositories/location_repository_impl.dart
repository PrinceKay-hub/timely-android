import 'package:cloud_firestore/cloud_firestore.dart';

class LocationRepositoryImpl {

  Future<Map<String, List<String>>> fetchAllRegions() async {
    final Map<String, List<String>> locationsData = {};

    try {
      final server = await FirebaseFirestore.instance
          .collection('regions')
          .get(); 
      final Map<String, List<String>> data = {};
      for (var doc in server.docs) {
        final name = doc['name'] as String;
        final districts = List<String>.from(doc['districts']);
        data[name] = districts;
        locationsData.addAll(data);
      }
      return locationsData;
    } catch (e) {
      throw Exception('Failed to get  regions: $e');
    }
  }
}
