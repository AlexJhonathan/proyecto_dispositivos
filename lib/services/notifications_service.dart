import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda la notificación en la colección 'notifications'
  Future<void> saveNotification({
    required String title,
    required String body,
  }) async {
    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene las notificaciones en tiempo real
  Stream<List<Map<String, dynamic>>> getNotifications() {
    return _db
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
