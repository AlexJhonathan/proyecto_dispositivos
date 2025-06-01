import 'package:cloud_firestore/cloud_firestore.dart';

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPoints(String userId, int pointsToAdd) async {
    final ref = _firestore.collection('usuarios').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      final currentPoints = snapshot.exists ? (snapshot['puntos'] ?? 0) : 0;
      final newPoints = currentPoints + pointsToAdd;

      transaction.set(ref, {'puntos': newPoints}, SetOptions(merge: true));
    });
  }

  Future<void> subtractPoints(String userId, int pointsToSubtract) async {
    final ref = _firestore.collection('usuarios').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      final currentPoints = snapshot.exists ? (snapshot['puntos'] ?? 0) : 0;
      final newPoints = (currentPoints - pointsToSubtract).clamp(0, double.infinity).toInt();

      transaction.set(ref, {'puntos': newPoints}, SetOptions(merge: true));
    });
  }

  Future<int> getCurrentPoints(String userId) async {
    final snapshot = await _firestore.collection('usuarios').doc(userId).get();

    if (snapshot.exists && snapshot.data()!.containsKey('puntos')) {
      return snapshot['puntos'];
    }
    return 0;
  }
}
