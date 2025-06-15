import 'package:flutter/material.dart';
import 'package:proyecto_dispositivos/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        setState(() => _isLoading = false);

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Inicio de sesión exitoso!')),
          );
          Navigator.pushNamed(context, '/navscreen');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
        );
      }
    }
  }

  void _onLeafIconPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("EcoGo: Cuidando el planeta 🌱")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 140, 198, 64),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(padding: EdgeInsets.only(right: 0),
                    child: Text(
                      "EcoGo",
                      style: TextStyle(
                        fontSize: 55, // más grande
                        fontWeight: FontWeight.w900, // más grueso
                        color: Colors.brown,
                      ),
                    ),
                    ),
                    
                    Padding(padding: EdgeInsets.only(left: 0),
                    child: IconButton(
                      icon: Icon(Icons.eco, color: Colors.white, size: 50),
                      onPressed: () { Navigator.pushNamed(context, '/authadminpage');},
                    
                    ),
                    ),
                    
                  ],
                ),
                SizedBox(height: 10),

                Text(
                  "Iniciar Sesión",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(
                  width: 285,
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese su correo' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'email@domain.com',
                    ),
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(
                  width: 285,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) =>
                        value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'Contraseña',
                    ),
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(
                  width: 285,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Ingresar"),
                  ),
                ),

                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/registerpage');
                  },
                  child: Text(
                    "Registrarse",
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
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
