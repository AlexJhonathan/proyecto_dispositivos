import 'package:flutter/material.dart';
import 'package:ecogo_app/services/noti_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> notifications = [];
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotiService().initNotification();
    
    // Escuchar nuevas notificaciones
    NotiService().onNotificationReceived = (title, body, timestamp) {
      setState(() {
        notifications.insert(0, NotificationItem(
          title: title,
          body: body,
          timestamp: timestamp,
          isRead: false,
        ));
      });
    };
  }

  void _loadNotifications() {
    // Cargar notificaciones guardadas (si las tienes almacenadas)
    final savedNotifications = NotiService().getSavedNotifications();
    setState(() {
      
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes activar el permiso de notificaciones para recibir alertas.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Permisos de notificaciones activados!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _markAsRead(int index) {
    setState(() {
      notifications[index].isRead = true;
    });
    // Guardar el estado (opcional)
    
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar notificaciones'),
          content: const Text('¿Estás seguro de que quieres eliminar todas las notificaciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notifications.clear();
                });
                NotiService().clearAllNotifications();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas las notificaciones eliminadas'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar todo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllNotifications,
              tooltip: 'Limpiar todo',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _requestNotificationPermission,
            tooltip: 'Configurar permisos',
          ),
        ],
      ),
      body: notifications.isEmpty 
        ? _buildEmptyState()
        : _buildNotificationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Botón para probar notificación local
          NotiService().showNotification(
            title: 'Notificación de prueba',
            body: 'Esta es una notificación de prueba generada localmente.',
          );
          
          // Agregar a la lista local
          setState(() {
            notifications.insert(0, NotificationItem(
              title: 'Notificación de prueba',
              body: 'Esta es una notificación de prueba generada localmente.',
              timestamp: DateTime.now(),
              isRead: false,
            ));
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando las recibas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _requestNotificationPermission,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Configurar notificaciones'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Column(
      children: [
        // Header con estadísticas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${notifications.length} notificaciones',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${notifications.where((n) => !n.isRead).length} sin leer',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de notificaciones
        Expanded(
          child: ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(notification, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, int index) {
    return Dismissible(
      key: Key('notification_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Eliminar notificación'),
              content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteNotification(index);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead 
            ? Colors.grey.shade300 
            : Colors.green,
          child: Icon(
            Icons.notifications,
            color: notification.isRead 
              ? Colors.grey.shade600 
              : Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead 
              ? FontWeight.normal 
              : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: notification.isRead 
          ? null 
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(index);
          }
          
          // Mostrar detalles completos
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(notification.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.body),
                  const SizedBox(height: 16),
                  Text(
                    'Recibida: ${notification.timestamp.toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Clase para representar una notificación
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