import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class RecuperarPasswordPage extends StatefulWidget {
  final String alias;

  RecuperarPasswordPage({required this.alias});

  @override
  State<RecuperarPasswordPage> createState() => _RecuperarPasswordPageState();
}

class _RecuperarPasswordPageState extends State<RecuperarPasswordPage> {
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController recoveryController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isLoading = false;
  bool claveVerificada = false;

  @override
  void initState() {
    super.initState();
    aliasController.text = widget.alias;
  }

  @override
  void dispose() {
    aliasController.dispose();
    recoveryController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
  }

  Future<void> _mostrarConfirmacionRecuperacion(String nuevaClave) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF21865B),
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Contraseña actualizada",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF321443),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tu contraseña se cambió correctamente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF665B6B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (nuevaClave.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EDF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Tu nueva clave de recuperación",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF665B6B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        nuevaClave,
                        style: const TextStyle(
                          color: Color(0xFF54216F),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7445A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Entendido"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  // VERIFICAR CLAVE DE RECUPERACIÓN
  Future<void> verificarClave() async {
    String alias = aliasController.text.trim();
    String recoveryCode = recoveryController.text.trim();

    if (alias.isEmpty || recoveryCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    if (recoveryCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La clave de recuperación debe tener 4 dígitos"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Primero verificamos la clave enviando una contraseña temporal.
      // El backend solamente debe comprobar alias + recoveryCode.
      var response = await http.post(
        apiUri('/verificar-recuperacion'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"alias": alias, "recoveryCode": recoveryCode}),
      );

      var data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (data["success"]) {
        setState(() {
          claveVerificada = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Clave de recuperación correcta")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }
  }

  // CAMBIAR CONTRASEÑA
  Future<void> recuperar() async {
    String alias = aliasController.text.trim();
    String recoveryCode = recoveryController.text.trim();
    String password = passwordController.text;
    String confirm = confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Completa todos los campos")));
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

    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.post(
        apiUri('/recuperar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alias": alias,
          "recoveryCode": recoveryCode,
          "password": password,
        }),
      );

      var data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (data["success"]) {
        final nuevaClave = data["recoveryCode"]?.toString() ?? "";
        await _mostrarConfirmacionRecuperacion(nuevaClave);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color moradoSuave = Color(0xFFAB8FB8);
    const Color moradoTexto = Color(0xFF7445A8);
    const Color borde = Color(0xFFB8A7C9);

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
                color: moradoSuave.withValues(alpha: 0.5),
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
                color: moradoSuave.withValues(alpha: 0.5),
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
                color: moradoSuave.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: "Regresar",
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: moradoTexto,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 540),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  padding: EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F352A3A),
                        blurRadius: 22,
                        offset: Offset(0, 8),
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
                          color: Color(0xFF17202A),
                        ),
                      ),

                      SizedBox(height: 25),

                      // ALIAS
                      TextField(
                        controller: aliasController,
                        enabled: !claveVerificada,
                        decoration: InputDecoration(
                          hintText: "Alias",
                          prefixIcon: const Icon(
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
                            borderSide: BorderSide(color: borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borde),
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

                      SizedBox(height: 20),

                      // CLAVE DE RECUPERACIÓN
                      TextField(
                        controller: recoveryController,
                        enabled: !claveVerificada,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          hintText: "Clave de recuperación",
                          prefixIcon: const Icon(
                            Icons.vpn_key,
                            color: moradoTexto,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borde),
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

                      if (!claveVerificada) ...[
                        SizedBox(height: 5),

                        Text(
                          "Ingresa la clave de recuperación que recibiste al crear tu cuenta.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),

                        SizedBox(height: 20),

                        // BOTÓN VERIFICAR
                        SizedBox(
                          width: 180,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : verificarClave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: moradoTexto,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Verificar"),
                          ),
                        ),
                      ],

                      // CONTRASEÑA
                      if (claveVerificada) ...[
                        SizedBox(height: 10),

                        Text(
                          "Clave verificada correctamente",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 20),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Nueva contraseña",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: moradoTexto,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borde),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borde),
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

                        SizedBox(height: 20),

                        TextField(
                          controller: confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Confirmar contraseña",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: moradoTexto,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borde),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borde),
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

                        SizedBox(height: 25),

                        // BOTÓN CAMBIAR CONTRASEÑA
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : recuperar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: moradoTexto,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Cambiar contraseña"),
                          ),
                        ),
                      ],
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
