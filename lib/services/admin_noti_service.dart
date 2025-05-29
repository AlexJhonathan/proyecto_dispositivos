import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminNotiService {
  // Configuración de tu proyecto Firebase
  static const String _projectId = 'proyectodispositivos-411d6';
  static const String _messagingSenderId = '738508294881';
  
  // NECESITAS OBTENER ESTE SERVER KEY DE FIREBASE CONSOLE
  static const String _serverKey = 'TU_SERVER_KEY_AQUI'; // Reemplazar con el Server Key real
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Envía una notificación a todos los usuarios suscritos a un tema
  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    String topic = 'all_users', // Tema al que todos los usuarios se suscriben
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': '/topics/$topic',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': {
            'type': 'admin_notification',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'notification': {
              'channel_id': 'ecogo_channel',
              'priority': 'high',
              'default_sound': true,
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Notificación enviada exitosamente');
        print('Response: ${response.body}');
      } else {
        throw Exception('Error al enviar notificación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en AdminNotiService: $e');
      throw Exception('Error al enviar notificación: $e');
    }
  }

  /// Envía notificación a dispositivos específicos usando sus tokens
  Future<void> sendNotificationToTokens({
    required String title,
    required String body,
    required List<String> tokens,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'registration_ids': tokens,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': {
            'type': 'admin_notification',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'notification': {
              'channel_id': 'ecogo_channel',
              'priority': 'high',
              'default_sound': true,
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Notificación enviada exitosamente a ${tokens.length} dispositivos');
        print('Response: ${response.body}');
      } else {
        throw Exception('Error al enviar notificación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en AdminNotiService: $e');
      throw Exception('Error al enviar notificación: $e');
    }
  }
}