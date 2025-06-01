import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importar la clase NotificationItem
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
    return NotificationItem(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  
  // Callback para cuando se recibe una notificación
  Function(String title, String body, DateTime timestamp)? onNotificationReceived;
  
  // Lista de notificaciones en memoria
  List<NotificationItem> _notifications = [];

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Cargar notificaciones guardadas
    await _loadNotificationsFromStorage();

    // Inicializar notificaciones locales
    await _initLocalNotifications();
    
    // Inicializar Firebase Cloud Messaging
    await _initFirebaseMessaging();
    
    _isInitialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _initFirebaseMessaging() async {
    // Solicitar permisos para notificaciones push
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Usuario autorizó las notificaciones');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Usuario autorizó notificaciones provisionales');
    } else {
      print('Usuario denegó las notificaciones');
    }

    // Obtener el token FCM del dispositivo
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Aquí puedes enviar el token a tu servidor para almacenarlo
    // await _sendTokenToServer(token);

    // Suscribirse al tema 'all_users' para recibir notificaciones broadcast
    await _firebaseMessaging.subscribeToTopic('all_users');
    print('Suscrito al tema all_users');

    // Manejar notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando el usuario toca una notificación (app cerrada o en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app fue abierta desde una notificación
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Manejar notificaciones en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Manejador para notificaciones en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Notificación recibida en foreground: ${message.notification?.title}');
    
    final title = message.notification?.title ?? 'Nueva notificación';
    final body = message.notification?.body ?? '';
    final timestamp = DateTime.now();
    
    // Guardar la notificación
    _saveNewNotification(title, body, timestamp);
    
    // Mostrar la notificación usando notificaciones locales
    showNotification(title: title, body: body);
    
    // Notificar a la UI si hay callback
    onNotificationReceived?.call(title, body, timestamp);
  }

  // Manejador cuando se toca una notificación
  void _handleNotificationTap(RemoteMessage message) {
    print('Notificación tocada: ${message.notification?.title}');
    
    final title = message.notification?.title ?? 'Notificación';
    final body = message.notification?.body ?? '';
    final timestamp = DateTime.now();
    
    // Guardar la notificación si no está ya guardada
    _saveNewNotification(title, body, timestamp);
    
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
    String? type = message.data['type'];
    if (type == 'admin_notification') {
      print('Notificación de administrador tocada');
    }
  }

  // Manejador para toques en notificaciones locales
  void _onNotificationTap(NotificationResponse notificationResponse) {
    print('Notificación local tocada: ${notificationResponse.payload}');
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'ecogo_channel',
        'Ecogo Notifications',
        channelDescription: 'Channel for Ecogo notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await initNotification();
    
    // Guardar la notificación localmente
    if (title != null && body != null) {
      _saveNewNotification(title, body, DateTime.now());
    }
    
    return notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }

  // Método para guardar una nueva notificación
  void _saveNewNotification(String title, String body, DateTime timestamp) {
    final newNotification = NotificationItem(
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: false,
    );
    
    _notifications.insert(0, newNotification);
    _saveNotificationsToStorage();
  }

  // Obtener notificaciones guardadas
  List<NotificationItem> getSavedNotifications() {
    return List.from(_notifications);
  }

  // Guardar notificaciones en el dispositivo
  Future<void> saveNotifications(List<NotificationItem> notifications) async {
    _notifications = notifications;
    await _saveNotificationsToStorage();
  }

  // Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotificationsToStorage();
  }

  // Guardar en SharedPreferences
  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('saved_notifications', jsonEncode(jsonList));
    } catch (e) {
      print('Error guardando notificaciones: $e');
    }
  }

  // Cargar desde SharedPreferences
  Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_notifications');
      
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _notifications = jsonList
            .map((json) => NotificationItem.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error cargando notificaciones: $e');
      _notifications = [];
    }
  }

  // Método para obtener el token FCM del dispositivo
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Método para enviar token al servidor (implementa según tu backend)
  Future<void> _sendTokenToServer(String? token) async {
    if (token != null) {
      // Implementa el envío del token a tu servidor aquí
      print('Enviando token al servidor: $token');
      
      // Ejemplo de implementación:
      // try {
      //   await http.post(
      //     Uri.parse('https://tu-servidor.com/api/fcm-tokens'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: jsonEncode({'token': token, 'platform': Platform.operatingSystem}),
      //   );
      // } catch (e) {
      //   print('Error enviando token: $e');
      // }
    }
  }
}

// Manejador de notificaciones en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Notificación recibida en background: ${message.notification?.title}');
}