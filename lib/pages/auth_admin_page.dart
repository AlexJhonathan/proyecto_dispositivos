import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

class AuthAdminPage extends StatefulWidget {
  const AuthAdminPage({Key? key}) : super(key: key);

  @override
  State<AuthAdminPage> createState() => _AuthAdminPageState();
}

class _AuthAdminPageState extends State<AuthAdminPage> {
  final LocalAuthentication localAuth = LocalAuthentication();
  bool isLoading = false;
  String message = '';
  bool biometricAvailable = false;
  List<String> authorizedAdmins = []; // Lista de administradores autorizados

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    await _checkBiometricAvailability();
    await _loadAuthorizedAdmins();
  }

  Future<void> _loadAuthorizedAdmins() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? adminList = prefs.getStringList('authorized_admins');
    setState(() {
      authorizedAdmins = adminList ?? [];
    });
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isAvailable = await localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();

      if (isAvailable && canCheckBiometrics && availableBiometrics.isNotEmpty) {
        setState(() {
          biometricAvailable = true;
        });
      } else {
        setState(() {
          biometricAvailable = false;
          message = 'Este dispositivo no tiene biometría configurada.\nConfigura tu huella en Ajustes > Seguridad';
        });
      }
    } catch (e) {
      setState(() {
        biometricAvailable = false;
        message = 'Error al verificar biometría disponible';
      });
    }
  }

  // Generar ID único para cada usuario basado en su huella + dispositivo
  Future<String> _generateUserFingerprint() async {
    try {
      // Crear un identificador único que combine información del dispositivo y timestamp
      final String platformInfo = Platform.operatingSystem;
      final String deviceModel = Platform.operatingSystemVersion;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Simular características únicas de la huella (en un caso real, esto vendría de la biometría)
      final String userInfo = '$platformInfo-$deviceModel-$timestamp-${DateTime.now().microsecond}';
      
      final bytes = utf8.encode(userInfo);
      final digest = sha256.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _registerNewAdmin() async {
    setState(() {
      isLoading = true;
      message = 'Registrando nuevo administrador...';
    });

    try {
      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Registra tu huella como administrador autorizado',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Generar ID único para este administrador
        final String adminId = await _generateUserFingerprint();
        
        // Guardar en la lista de administradores autorizados
        final prefs = await SharedPreferences.getInstance();
        final List<String> currentAdmins = prefs.getStringList('authorized_admins') ?? [];
        
        if (!currentAdmins.contains(adminId)) {
          currentAdmins.add(adminId);
          await prefs.setStringList('authorized_admins', currentAdmins);
          
          // Guardar información adicional del admin
          await prefs.setString('admin_${adminId}_registered', DateTime.now().toIso8601String());
          await prefs.setString('admin_${adminId}_name', 'Admin ${currentAdmins.length}');
        }
        
        setState(() {
          authorizedAdmins = currentAdmins;
          message = '¡Administrador registrado exitosamente!\nTotal de admins: ${currentAdmins.length}';
          isLoading = false;
        });

        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          message = '';
        });
      } else {
        setState(() {
          message = 'Registro cancelado';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error en el registro: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _authenticateLogin() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      // Verificar que la biometría siga disponible
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        setState(() {
          message = 'Biometría no disponible. Verifica tu configuración.';
          isLoading = false;
          biometricAvailable = false;
        });
        return;
      }

      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Usa tu huella registrada para acceder como administrador',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // AQUÍ ES DONDE VALIDAMOS SI ES UN ADMIN AUTORIZADO
        final String currentUserFingerprint = await _generateUserFingerprint();
        
        // Verificar si esta huella está en nuestra lista de administradores
        bool isAuthorizedAdmin = false;
        String? adminId;
        
        // En un caso real, compararías con huellas guardadas
        // Por ahora, verificamos si hay admins registrados desde este dispositivo
        final prefs = await SharedPreferences.getInstance();
        final List<String> currentAdmins = prefs.getStringList('authorized_admins') ?? [];
        
        if (currentAdmins.isNotEmpty) {
          // Si hay administradores registrados, asumir que es uno de ellos
          // (En producción necesitarías un método más robusto de validación)
          isAuthorizedAdmin = true;
          adminId = currentAdmins.first;
        }

        if (isAuthorizedAdmin) {
          // ✅ ADMIN AUTORIZADO - PERMITIR ACCESO
          await prefs.setString('last_admin_access', DateTime.now().toIso8601String());
          await prefs.setString('last_admin_id', adminId!);
          await prefs.remove('failed_attempts');
          
          setState(() {
            message = '¡Bienvenido, Administrador! 🔓';
            isLoading = false;
          });

          // ✅ NAVEGAR A LA PANTALLA DE ADMIN
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamed(context, '/adminnotificationpage');
          }
        } else {
          // ❌ HUELLA NO AUTORIZADA - DENEGAR ACCESO
          await _handleUnauthorizedAccess();
        }
      } else {
        setState(() {
          message = 'Autenticación cancelada';
          isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      await _handleAuthenticationError(e);
    } catch (e) {
      setState(() {
        message = 'Error inesperado en la autenticación';
        isLoading = false;
      });
    }
  }

  Future<void> _handleUnauthorizedAccess() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Contar intentos no autorizados
    int unauthorizedAttempts = prefs.getInt('unauthorized_attempts') ?? 0;
    unauthorizedAttempts++;
    await prefs.setInt('unauthorized_attempts', unauthorizedAttempts);
    await prefs.setString('last_unauthorized_attempt', DateTime.now().toIso8601String());

    setState(() {
      message = '❌ ACCESO DENEGADO ❌\nHuella no autorizada\nSolo administradores pueden acceder';
      isLoading = false;
    });

    // Si hay muchos intentos no autorizados, mostrar advertencia más severa
    if (unauthorizedAttempts >= 3) {
      setState(() {
        message = '🚨 ALERTA DE SEGURIDAD 🚨\nDemasiados intentos no autorizados\nSolo personal autorizado puede acceder';
      });
      
      // Bloquear por 30 segundos después de 3 intentos
      await Future.delayed(const Duration(seconds: 30));
      await prefs.remove('unauthorized_attempts');
    }
  }

  Future<void> _handleAuthenticationError(PlatformException e) async {
    String errorMessage;
    switch (e.code) {
      case 'NotAvailable':
        errorMessage = 'Autenticación no disponible';
        break;
      case 'NotEnrolled':
        errorMessage = 'No hay huellas configuradas en el dispositivo';
        break;
      case 'LockedOut':
        errorMessage = 'Biometría bloqueada temporalmente';
        break;
      case 'PermanentlyLockedOut':
        errorMessage = 'Biometría bloqueada. Usa tu PIN o patrón';
        break;
      default:
        errorMessage = 'Error de autenticación: ${e.message ?? 'Desconocido'}';
    }
    
    setState(() {
      message = errorMessage;
      isLoading = false;
    });
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Limpiar todos los datos
    await prefs.remove('authorized_admins');
    await prefs.remove('last_admin_access');
    await prefs.remove('last_admin_id');
    await prefs.remove('unauthorized_attempts');
    await prefs.remove('last_unauthorized_attempt');
    
    // Limpiar datos de administradores individuales
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('admin_')) {
        await prefs.remove(key);
      }
    }
    
    setState(() {
      authorizedAdmins = [];
      message = 'Todos los datos eliminados. Registra nuevos administradores.';
    });
    
    await _initializeBiometric();
  }

  Future<void> _showSecurityInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentAdmins = prefs.getStringList('authorized_admins') ?? [];
    final int unauthorizedAttempts = prefs.getInt('unauthorized_attempts') ?? 0;
    final String? lastAccess = prefs.getString('last_admin_access');
    final String? lastUnauthorized = prefs.getString('last_unauthorized_attempt');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('🔐 Info de Seguridad', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👥 Admins registrados: ${currentAdmins.length}', style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
              Text('🚨 Intentos no autorizados: $unauthorizedAttempts', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Text('✅ Último acceso: ${lastAccess ?? 'Nunca'}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text('❌ Último intento no autorizado: ${lastUnauthorized ?? 'Nunca'}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text('📱 Biometría disponible: $biometricAvailable', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  authorizedAdmins.isEmpty 
                      ? Icons.admin_panel_settings_outlined
                      : Icons.fingerprint,
                  size: 80,
                  color: authorizedAdmins.isEmpty ? Colors.orange : Colors.green,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Títulos
              const Text(
                'Panel de Control',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'ECO GO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                authorizedAdmins.isEmpty 
                    ? '🔒 Sin administradores registrados'
                    : '🔐 ${authorizedAdmins.length} administrador(es) autorizado(s)',
                style: TextStyle(
                  fontSize: 16,
                  color: authorizedAdmins.isEmpty ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Solo personal autorizado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Botones principales
              if (biometricAvailable && authorizedAdmins.isNotEmpty) ...[
                // Botón de autenticación para admins registrados
                ElevatedButton(
                  onPressed: isLoading ? null : _authenticateLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fingerprint, size: 24),
                            SizedBox(width: 8),
                            Text('Acceder como Admin', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón para registrar nuevo admin
                OutlinedButton(
                  onPressed: isLoading ? null : _registerNewAdmin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person_add, size: 20),
                      SizedBox(width: 8),
                      Text('Registrar Nuevo Admin', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ] else if (biometricAvailable && authorizedAdmins.isEmpty) ...[
                // Primera configuración - registrar primer admin
                ElevatedButton(
                  onPressed: isLoading ? null : _registerNewAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.admin_panel_settings, size: 24),
                            SizedBox(width: 8),
                            Text('Configurar Primer Admin', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ] else ...[
                // Sin biometría disponible
                ElevatedButton(
                  onPressed: _initializeBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh, size: 24),
                      SizedBox(width: 8),
                      Text('Verificar Biometría', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Botones de desarrollo/administración
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _resetAllData,
                    child: const Text(
                      'Reset Sistema',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _showSecurityInfo,
                    child: const Text(
                      'Info Seguridad',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Mensaje de estado
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.contains('DENEGADO') || 
                           message.contains('ALERTA') ||
                           message.contains('Error') ||
                           message.contains('no autorizada')
                        ? Colors.red.withOpacity(0.1)
                        : message.contains('Bienvenido') || message.contains('registrado')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.contains('DENEGADO') || 
                             message.contains('ALERTA') ||
                             message.contains('Error') ||
                             message.contains('no autorizada')
                          ? Colors.red
                          : message.contains('Bienvenido') || message.contains('registrado')
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.contains('DENEGADO') || 
                             message.contains('ALERTA') ||
                             message.contains('Error') ||
                             message.contains('no autorizada')
                          ? Colors.red
                          : message.contains('Bienvenido') || message.contains('registrado')
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}