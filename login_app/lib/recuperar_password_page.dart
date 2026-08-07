import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecuperarPasswordPage extends StatefulWidget {
  final String alias;

  RecuperarPasswordPage({required this.alias});
  @override
  State<RecuperarPasswordPage> createState() => _RecuperarPasswordPageState();
}

class _RecuperarPasswordPageState extends State<RecuperarPasswordPage> {
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isLoading = false;

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
  }

  Future<void> recuperar() async {
    String password = passwordController.text;
    String confirm = confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    if (aliasController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ingresa tu alias")));
      return;
    }

    if (!validarPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y símbolo",
          ),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("http://localhost:3000/recuperar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"alias": aliasController.text, "password": password}),
      );

      var data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["success"]) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Contraseña actualizada")));

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color morado = Color(0xFFAB8FB8);

    return Scaffold(
      backgroundColor: Color(0xFFF3EDF5),

      body: Stack(
        children: [
          // CÍRCULO DECORATIVO
          Positioned(
            top: -150,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: morado.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 25),
                padding: EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Recuperar contraseña",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: morado,
                      ),
                    ),

                    SizedBox(height: 25),

                    // ALIAS
                    TextField(
                      controller: aliasController,
                      decoration: InputDecoration(
                        labelText: "Alias",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // NUEVA CONTRASEÑA
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Nueva contraseña",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // CONFIRMAR
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirmar contraseña",
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    // BOTÓN
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(
                        onPressed: recuperar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: morado,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text("Recuperar"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
