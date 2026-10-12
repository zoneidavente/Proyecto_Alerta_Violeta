import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class RegistroPage extends StatefulWidget {
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  bool isLoading = false;

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
  }

  Future<void> registrar() async {
    if (aliasController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmarController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    if (passwordController.text != confirmarController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Las contraseñas no coinciden")));
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
      final response = await http.post(
        Uri.parse("http://localhost:3000/registrar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alias": aliasController.text,
          "password": passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"]) {
        final recoveryCode = data["recoveryCode"]?.toString() ?? "";

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: Color(0xFFF7F0F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Color(0xFF6C3A7A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 42),
                    ),

                    SizedBox(height: 18),

                    Text(
                      "Cuenta creada correctamente",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2E3F),
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      "Guarda este código en un lugar seguro. Lo necesitarás si pierdes el acceso a tu cuenta.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4E4550),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFE7D8EC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Código de recuperación",
                            style: TextStyle(
                              color: Color(0xFF4E4550),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            recoveryCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B2D5D),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      "Este código se mostrará una sola vez.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7C6F78), fontSize: 12),
                    ),

                    SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: recoveryCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Código copiado"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(Icons.copy_all_outlined, size: 18),
                            label: Text("Copiar código"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF4B2D5D),
                              side: BorderSide(color: Color(0xFFB39AC4)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(
                                    alias: aliasController.text,
                                    role: "Usuario",
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6C3A7A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text("Continuar"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "No se pudo registrar")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color moradoHeader = const Color(0xFFA788DC);
    final Color moradoPrincipal = const Color(0xFFB68AD9);
    final Color moradoFondo = const Color(0xFFE7D9F2);
    final Color fondoGeneral = const Color(0xFFF5F3F6);
    final Color textoPrincipal = const Color(0xFF5B3B73);

    return Scaffold(
      backgroundColor: fondoGeneral,
      appBar: AppBar(
        backgroundColor: moradoHeader,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.only(left: 10),
              splashRadius: 24,
            ),
            const Text(
              "Regresar",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: moradoFondo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: moradoFondo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                child: Container(
                  width: 430,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: moradoPrincipal.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 52,
                          color: moradoPrincipal,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Crear una cuenta",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B3B73),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Para mantener tu anonimo solo necesitas un alias y una contraseña.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6F6375),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 22),

                      _buildInputField(
                        controller: aliasController,
                        hintText: "Alias",
                        icon: Icons.person_outline_rounded,
                        obscureText: false,
                        fillColor: moradoPrincipal,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: passwordController,
                        hintText: "Contraseña",
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        fillColor: moradoPrincipal,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: confirmarController,
                        hintText: "Confirmar contraseña",
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        fillColor: moradoPrincipal,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 200,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moradoPrincipal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Registrarse",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required Color fillColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: fillColor,
        prefixIcon: Icon(icon, color: Colors.white, size: 22),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
