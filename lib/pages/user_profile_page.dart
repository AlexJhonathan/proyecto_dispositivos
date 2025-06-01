import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Timer? _factTimer;
  int _currentFactIndex = 0;
  bool _showFact = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Datos del usuario (simulados)
  final String username = "EcoWarrior2024";
  final String profileImage = "assets/profile_placeholder.png";
  final int level = 12;
  final int ecoCoins = 2450;
  final int streakDays = 15;
  final DateTime registrationDate = DateTime(2024, 1, 15);
  final int productExchanges = 8;

  // Datos curiosos sobre basura
  final List<String> environmentalFacts = [
    "Una botella de plástico tarda hasta 450 años en descomponerse completamente en la naturaleza.",
    "Cada año, 8 millones de toneladas de plástico terminan en nuestros océanos.",
    "Una lata de aluminio puede reciclarse infinitas veces sin perder calidad.",
    "El 91% de los plásticos no se reciclan y terminan en vertederos o el medio ambiente.",
    "Una colilla de cigarrillo puede contaminar hasta 50 litros de agua potable."
  ];

  // Ranking semanal (datos simulados)
  final List<Map<String, dynamic>> weeklyRanking = [
    {"name": "EcoMaster", "points": 3200, "position": 1},
    {"name": "GreenHero", "points": 2800, "position": 2},
    {"name": "EcoWarrior2024", "points": 2450, "position": 3},
    {"name": "PlantLover", "points": 2100, "position": 4},
    {"name": "RecycleKing", "points": 1950, "position": 5},
  ];

  @override
  void initState() {
    super.initState();
    _startFactTimer();
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  void _startFactTimer() {
    // Mostrar el primer dato inmediatamente para prueba
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFact = true;
          _currentFactIndex = Random().nextInt(environmentalFacts.length);
        });
      }
    });

    _factTimer = Timer.periodic(Duration(seconds: 30), (timer) { // Cambiado a 30 segundos para prueba
      setState(() {
        _showFact = true;
        _currentFactIndex = Random().nextInt(environmentalFacts.length);
      });
      
      // Ocultar el dato después de 15 segundos
      Timer(Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _showFact = false;
          });
        }
      });
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStreakMedal() {
    if (streakDays >= 30) return "🏆";
    if (streakDays >= 14) return "🥇";
    if (streakDays >= 7) return "🥈";
    if (streakDays >= 3) return "🥉";
    return "⭐";
  }

  String _getProfileFrame() {
    if (productExchanges >= 20) return "Maestro del Canje";
    if (productExchanges >= 10) return "Canjeador Experto";
    if (productExchanges >= 5) return "Canjeador Activo";
    return "Nuevo Canjeador";
  }

  String _getUserTitle() {
    if (productExchanges >= 25) return "Eco Emperador";
    if (productExchanges >= 15) return "Guardián Verde";
    if (productExchanges >= 10) return "Héroe del Reciclaje";
    if (productExchanges >= 5) return "Eco Guerrero";
    return "Aprendiz Ecológico";
  }

  Color _getFrameColor() {
    if (productExchanges >= 20) return Colors.purple;
    if (productExchanges >= 10) return Colors.orange;
    if (productExchanges >= 5) return Colors.blue;
    return Colors.grey;
  }

  int _getDaysPlaying() {
    return DateTime.now().difference(registrationDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      appBar: AppBar(
        title: Text('Mi Perfil Eco', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Perfil básico
                _buildProfileCard(),
                SizedBox(height: 16),
                
                // Estadísticas
                _buildStatsCard(),
                SizedBox(height: 16),
                
                // Ranking semanal
                _buildRankingCard(),
                SizedBox(height: 20),
              ],
            ),
          ),
          
          // Ventana deslizante con datos curiosos
          if (_showFact) _buildFactSlider(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Foto de perfil con marco
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getFrameColor(),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null 
                          ? FileImage(_profileImage!) 
                          : null,
                      child: _profileImage == null 
                          ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            
            // Título del usuario
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _getUserTitle(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            
            // Username
            Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            // Marco del perfil
            Text(
              _getProfileFrame(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            
            // Nivel y EcoCoins
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Nivel", level.toString(), Icons.star),
                _buildStatItem("EcoCoins", ecoCoins.toString(), Icons.monetization_on),
                _buildStatItem("Días jugando", _getDaysPlaying().toString(), Icons.calendar_today),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Logros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 16),
            
            // Racha de días
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    _getStreakMedal(),
                    style: TextStyle(fontSize: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Racha de días',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$streakDays días consecutivos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            
            // Productos canjeados
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.redeem, size: 30, color: Color(0xFF4CAF50)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productos canjeados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$productExchanges canjes realizados',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Ranking Semanal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            ...weeklyRanking.map((player) => _buildRankingItem(player)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> player) {
    bool isCurrentUser = player['name'] == username;
    Color bgColor = isCurrentUser ? Color(0xFFE8F5E8) : Colors.transparent;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser ? Border.all(color: Color(0xFF4CAF50), width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getRankingColor(player['position']),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player['position'].toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              player['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${player['points']} pts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankingColor(int position) {
    switch (position) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[400]!;
      case 3: return Colors.brown[300]!;
      default: return Color(0xFF4CAF50);
    }
  }

  Widget _buildFactSlider() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 8,
          color: Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '¿Sabías que...?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          _showFact = false;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  environmentalFacts[_currentFactIndex],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}