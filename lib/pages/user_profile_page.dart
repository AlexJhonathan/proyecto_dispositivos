import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_dispositivos/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> topUsers = [];
  Timer? _factTimer;
  int _currentFactIndex = 0;
  bool _showFact = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final List<String> environmentalFacts = [
    "Una botella de plástico tarda hasta 450 años en descomponerse.",
    "8 millones de toneladas de plástico terminan en el mar anualmente.",
    "Una lata de aluminio puede reciclarse infinitas veces.",
    "El 91% de los plásticos no se reciclan.",
    "Una colilla de cigarro contamina 50 L de agua."
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    Future.delayed(Duration.zero, () {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.cargarPuntosUsuario(); // Carga inicial de puntos
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      _startFactTimer();
    }
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  void _startFactTimer() {
    _factTimer?.cancel();
    setState(() {
      _currentFactIndex = DateTime.now().millisecondsSinceEpoch % environmentalFacts.length;
      _showFact = true;
    });
    Future.delayed(Duration(seconds: 15), () {
      if (mounted) setState(() => _showFact = false);
    });
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = await authService.fetchCurrentUserData();
    final ranking = await authService.fetchTop5Users();
    setState(() {
      userData = data;
      topUsers = ranking;
    });
  }

  Future<void> _pickImage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 128, maxHeight: 128, imageQuality: 50);
    if (img != null) {
      final bytes = await img.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() => _profileImage = File(img.path));
      await authService.updatePhotoUrl(base64Image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final puntos = authService.puntos;
    final u = userData;
    if (u == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final username = u['username'] ?? '';
    final photoUrl = u['photoUrl'] as String?;
    final registrationDate = (u['registrationDate'] as Timestamp).toDate();
    final streak = u['streak'] as int? ?? 0;
    final daysPlaying = DateTime.now().difference(registrationDate).inDays;

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      appBar: AppBar(title: Text('Mi Perfil Eco'), backgroundColor: Color.fromARGB(255, 140, 198, 64), foregroundColor: Colors.white,),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Card perfil
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [Color.fromARGB(255, 140, 198, 64), Color.fromARGB(255, 140, 198, 64)]),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (photoUrl != null && photoUrl.isNotEmpty
                                  ? (photoUrl.startsWith('http')
                                      ? NetworkImage(photoUrl)
                                      : MemoryImage(base64Decode(photoUrl)))
                                  : null) as ImageProvider<Object>?,
                          child: _profileImage == null && (photoUrl?.isEmpty ?? true)
                              ? Icon(Icons.person, size: 60, color: Colors.white70)
                              : null,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Canejador Activo', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem('Puntos', puntos.toString(), Icons.monetization_on),
                          _statItem('Días jugados', daysPlaying.toString(), Icons.calendar_today),
                          _statItem('Racha', streak.toString(), Icons.whatshot),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Ranking
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ranking Semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      SizedBox(height: 12),
                      ...topUsers.map((p) {
                        final isMe = p['username'] == username;
                        return Container(
                          decoration: isMe
                              ? BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                )
                              : null,
                          child: ListTile(
                            leading: isMe ? Icon(Icons.person_pin, color: Colors.green) : Icon(Icons.person),
                            title: Text(p['username']),
                            trailing: isMe
                            ? Consumer<AuthService>(
                                builder: (_, auth, __) => Text('${auth.puntos} pts'),
                              )
                            : Text('${p['points']} pts'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showFact)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Color(0xFF2E7D32),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.yellow),
                      SizedBox(width: 8),
                      Expanded(child: Text(environmentalFacts[_currentFactIndex], style: TextStyle(color: Colors.white))),
                      IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showFact = false)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(height: 4),
          Text(val, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white70)),
        ],
      );
}
