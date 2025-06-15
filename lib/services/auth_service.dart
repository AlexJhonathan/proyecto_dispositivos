import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  int _puntos = 0;

  int get puntos => _puntos;
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserCredential> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // Registro con creación de documento user
  Future<User?> createAccount({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        final username = email.split('@')[0];
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'photoUrl': '',
          'points': 0,
          'registrationDate': FieldValue.serverTimestamp(),
          'lastLoginDate': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print('Error al crear usuario: $e');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();
  Future<void> resetPassword({required String email}) => _auth.sendPasswordResetEmail(email: email);
  Future<void> updateUsername({required String username}) async {
    await currentUser?.updateDisplayName(username);
    await _firestore.collection('users').doc(currentUser!.uid).update({'username': username});
  }

  // Actualizar foto de perfil en Firestore
  Future<void> updatePhotoUrl(String url) async {
    await _firestore.collection('users').doc(currentUser!.uid).update({'photoUrl': url});
  }

  // Sumar o restar puntos
  Future<void> changePoints(int delta) async {
    final ref = _firestore.collection('users').doc(currentUser!.uid);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final currentPoints = snapshot.get('points') as int;
      tx.update(ref, {'points': currentPoints + delta});
    });
  }

  // Registrar día de login y racha
  Future<void> updateLoginDate() async {
    final ref = _firestore.collection('users').doc(currentUser!.uid);
    final snapshot = await ref.get();
    final last = (snapshot.data()?['lastLoginDate'] as Timestamp).toDate();
    final now = DateTime.now();
    if (now.difference(last).inDays >= 1) {
      // Si entró un día nuevo, puedes manejar racha aquí
      // Ej: incrementar campo 'streak'
    }
    await ref.update({'lastLoginDate': now});
  }

  // Obtener datos de usuario actual
  Future<Map<String, dynamic>?> fetchCurrentUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Top 5 usuarios por puntos
  Future<List<Map<String, dynamic>>> fetchTop5Users() async {
    final q = await _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(5) // top 5 :contentReference[oaicite:7]{index=7}
        .get();
    return q.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> cargarPuntosUsuario() async {
    if (currentUser == null) return;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    if (doc.exists && doc.data()!.containsKey('points')) {
      _puntos = doc['points'] ?? 0;
      notifyListeners();
    }
  }

  // Resta puntos si hay suficientes y actualiza en Firestore
  Future<bool> restarPuntos(int cantidad) async {
    if (_puntos >= cantidad) {
      _puntos -= cantidad;
      notifyListeners();

      final ref = _firestore.collection('users').doc(currentUser!.uid);
      await ref.update({'points': _puntos});

      return true;  // éxito
    } else {
      return false; // no hay puntos suficientes
    }
  }
  Future<bool> sumarPuntos(int cantidad) async {
      _puntos += cantidad;
      notifyListeners();

      final ref = _firestore.collection('users').doc(currentUser!.uid);
      await ref.update({'points': _puntos});

      return true;  // éxito
  }
}
