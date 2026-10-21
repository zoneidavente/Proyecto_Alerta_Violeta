import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recuperar_password_page.dart';
import 'registro_page.dart';
import 'api_config.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void dispose() {
    aliasController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
  }

  void irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistroPage()),
    );
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
        apiUri('/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alias": aliasController.text,
          "password": passwordController.text,
        }),
      );

      var data = jsonDecode(response.body);

      if (data["success"]) {
        String role = data["role"] ?? "usuario";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(alias: aliasController.text, role: role),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Credenciales incorrectas"),
          ),
        );
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
    const Color moradoSuave = Color(0xFFAB8FB8);
    const Color moradoTexto = Color(0xFF7445A8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
          Positioned(
            right: -165,
            bottom: -160,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: moradoSuave.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -105,
            bottom: -110,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: moradoSuave.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      elevation: 8,
                      shadowColor: moradoSuave.withOpacity(0.2),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 29,
                              backgroundColor: moradoSuave.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 34,
                                color: moradoTexto,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Bienvenido",
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17202A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Ingresa a tu cuenta",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: aliasController,
                              decoration: InputDecoration(
                                hintText: "Alias",
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: moradoTexto,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB8A7C9),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB8A7C9),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: moradoTexto,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: "Contraseña",
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: moradoTexto,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? "Mostrar contraseña"
                                      : "Ocultar contraseña",
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: moradoTexto,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB8A7C9),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB8A7C9),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: moradoTexto,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Checkbox(
                                    value: rememberMe,
                                    activeColor: moradoTexto,
                                    onChanged: (value) {
                                      setState(() {
                                        rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    "Recordarme",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: recoverAccount,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "¿Olvidaste tu contraseña?",
                                    style: TextStyle(
                                      color: moradoTexto,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: moradoTexto,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Iniciar sesión",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: irARegistro,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text.rich(
                                TextSpan(
                                  text: "¿No tienes una cuenta? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Regístrate",
                                      style: TextStyle(
                                        color: moradoTexto,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
