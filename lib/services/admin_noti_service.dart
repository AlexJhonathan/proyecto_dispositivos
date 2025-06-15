import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    DateTime timestamp;

    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate(); // Convierte correctamente
    } else if (rawTimestamp is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else {
      timestamp = DateTime.now(); // Valor por defecto en caso de error
    }

    return NotificationItem(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: timestamp,
      isRead: json['isRead'] ?? false,
    );
  }
}

class AdminNotiService {
  StreamSubscription? _subscription;

  void Function(String title, String body, DateTime timestamp)? onNotificationReceived;

  void listenToNotifications() {
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data();
          if (data != null && data['timestamp'] != null) {
            final item = NotificationItem.fromJson(data);
            onNotificationReceived?.call(item.title, item.body, item.timestamp);
          }
        }
      }
    });
  }

  void cancelListener() {
    _subscription?.cancel();
  }

  Future<void> saveNotification({
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .where((doc) => doc['timestamp'] != null)
        .map((doc) => NotificationItem.fromJson(doc.data()))
        .toList();
  }

  Future<void> clearAllNotifications() async {
    final batch = FirebaseFirestore.instance.batch();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .get();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
