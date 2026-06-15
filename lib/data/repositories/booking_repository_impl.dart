import 'package:booking/domain/entities/booking_entity.dart';
import 'package:booking/domain/repositories/booking_repository.dart';
import 'package:booking/data/models/booking_model.dart';
import 'package:booking/core/network/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRepositoryImpl extends BookingRepository {
  final FirebaseService firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BookingRepositoryImpl({FirebaseService? firebaseService})
      : firebaseService = firebaseService ?? FirebaseService();

  @override
  Future<String> createBooking(BookingEntity booking) async {
    try {
      final bookingData = BookingModel.fromEntity(booking).toJson();
      bookingData.remove('id');
      
      final docRef = await _firestore.collection('appointments').add(bookingData);
      
      // Update with generated ID
      await _firestore.collection('appointments').doc(docRef.id).update({
        'id': docRef.id,
      });

      // Create notification for service provider
      await _createProviderNotification(docRef.id, booking);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<void> _createProviderNotification(String bookingId, BookingEntity booking) async {
    try {
      await _firestore.collection('notifications').add({
        'id': '',
        'type': 'appointment',
        'title': 'New Appointment Booking',
        'body': '${booking.serviceName} - ${booking.timeSlot.displayTime}',
        'userId': booking.providerId,
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to create notification: $e');
    }
  }

   @override
  Future<void> confirmBooking(String bookingId)async{
    try {
      await _firestore.collection('appointments').doc(bookingId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('appointments').doc(bookingId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  @override
   Stream<List<Map<String, dynamic>>> getUserBookings(String userId) {
    return _firestore
        .collection('appointments')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }
 /* Future<List> getUserBookings(String userId) async {
    List<Map<dynamic, dynamic>> bookingList = [];
    List item = [];
    try {
      await _firestore
          .collection('appointments')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .then(
        (value) {
          bookingList = value.docs
              .map((e) => e.data(), ).toList();
          //postList = value.docs.toList();
          if (bookingList.isNotEmpty) {
            for (var l in bookingList) {
              item.add(l);
              //print(l);
            }
          }
        });
      return item;
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }*/
  
  @override
  Future<void> updateBooking(String bookingId, DateTime appointmentDate, TimeSlot timeSlot) async{
    try {
      await _firestore.collection('appointments').doc(bookingId).update({
        'appointmentDate': appointmentDate,
        'timeSlot': {
          'displayTime': timeSlot.displayTime,
          'time': timeSlot.time,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reschedule booking: $e');
    }
  }
  
  @override
  Future<void> deleteBooking(String bookingId) async{
    try {
      await _firestore.collection('appointments').doc(bookingId).delete();
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }


 
}