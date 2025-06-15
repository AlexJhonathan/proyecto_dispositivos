import 'package:flutter/material.dart';
import 'package:proyecto_dispositivos/services/admin_noti_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> notifications = [];
  final AdminNotiService _notiService = AdminNotiService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notiService.cancelListener();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      final fetchedNotifications = await _notiService.fetchNotifications();
      print("Notificaciones cargadas: ${fetchedNotifications.length}");
      setState(() {
        notifications = fetchedNotifications;
      });
    } catch (e) {
      print("Error al cargar notificaciones: $e");
    }

    _notiService.onNotificationReceived = (title, body, timestamp) {
      final exists = notifications.any((n) =>
        n.title == title &&
        n.body == body &&
        n.timestamp == timestamp,
      );

      if (!exists) {
        setState(() {
          notifications.insert(
            0,
            NotificationItem(
              title: title,
              body: body,
              timestamp: timestamp,
            ),
          );
        });
      }
    };

  }


  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;

    final isGranted = status.isGranted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isGranted
            ? '¡Permisos de notificaciones activados!'
            : 'Debes activar el permiso de notificaciones para recibir alertas.'),
        backgroundColor: isGranted ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Color.fromARGB(255, 140, 198, 64),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _requestNotificationPermission,
            tooltip: 'Permisos',
          ),
        ],
      ),
      backgroundColor:Color(0xFFE8F5E8),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'Sin notificaciones aún',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final noti = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(noti.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(noti.body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(noti.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _initializeNotifications,
            child: Icon(Icons.refresh, color: Colors.white),
            backgroundColor: Color.fromARGB(255, 47, 147, 255),
            tooltip: 'Actualizar notificaciones',
            heroTag: 'refresh',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () async {
              await _notiService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Todas las notificaciones han sido eliminadas')),
              );
              _initializeNotifications();
            },
            child: Icon(Icons.delete, color: Colors.white),
            backgroundColor: const Color.fromARGB(255, 255, 34, 78),
            tooltip: 'Eliminar notificaciones',
            heroTag: 'delete',
          ),
        ],
      ),
      
    );
  }
}
