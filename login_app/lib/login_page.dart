import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recuperar_password_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
  }

  Future<void> login() async {
    if (aliasController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Completa todos los campos")));

      return;
    }

    if (!validarPassword(passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y símbolo",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse("http://localhost:3000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alias": aliasController.text,
          "password": passwordController.text,
        }),
      );

      var data = jsonDecode(response.body);

      if (data["success"]) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(alias: aliasController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Credenciales incorrectas")));
      }
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      isLoading = false;
    });
  }

  void recoverAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecuperarPasswordPage(alias: aliasController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color moradoSuave = Color(0xFFAB8FB8);

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // CÍRCULO OSCURO
          Positioned(
            top: -300,
            left: -130,
            child: Container(
              width: 995,
              height: 465,
              decoration: BoxDecoration(
                color: moradoSuave,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // CÍRCULO CLARO
          Positioned(
            top: -180,
            left: -100,
            child: Container(
              width: 490,
              height: 465,
              decoration: BoxDecoration(
                color: moradoSuave.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 80),

                      // ICONO
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: moradoSuave.withOpacity(0.2),
                        child: Icon(Icons.person, size: 60, color: moradoSuave),
                      ),

                      SizedBox(height: 40),

                      // CAMPO ALIAS
                      SizedBox(
                        width: 460,

                        child: TextField(
                          controller: aliasController,

                          decoration: InputDecoration(
                            hintText: "Alias",

                            filled: true,
                            fillColor: moradoSuave,

                            hintStyle: TextStyle(color: Colors.white),

                            prefixIcon: Icon(Icons.person, color: Colors.white),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),

                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 20),

                      // CAMPO PASSWORD
                      SizedBox(
                        width: 460,

                        child: TextField(
                          controller: passwordController,
                          obscureText: true,

                          decoration: InputDecoration(
                            hintText: "Contraseña",

                            filled: true,
                            fillColor: moradoSuave,

                            hintStyle: TextStyle(color: Colors.white),

                            prefixIcon: Icon(Icons.lock, color: Colors.white),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),

                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      SizedBox(height: 30),

                      // BOTÓN LOGIN PEQUEÑO Y CENTRADO
                      SizedBox(
                        width: 180,
                        height: 50,

                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: moradoSuave,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Iniciar Sesión",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 25),

                      // RECUPERAR CONTRASEÑA ABAJO
                      TextButton(
                        onPressed: recoverAccount,
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(color: moradoSuave, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
