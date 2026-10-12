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
  final TextEditingController recoveryController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isLoading = false;
  bool claveVerificada = false;

  bool validarPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#])[A-Za-z\d@$!%*?&.#]{8,}$',
    );

    return regex.hasMatch(password);
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
        Uri.parse("http://localhost:3000/verificar-recuperacion"),
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
        Uri.parse("http://localhost:3000/recuperar"),
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
        String nuevaClave = data["recoveryCode"] ?? "";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Contraseña actualizada. Tu nueva clave de recuperación es: $nuevaClave",
            ),
            duration: Duration(seconds: 6),
          ),
        );

        Navigator.pop(context);
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
    const Color morado = Color(0xFF9B78AA);
    const Color borde = Color(0xFF8F8792);

    return Scaffold(
      backgroundColor: Color(0xFFF3EDF5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF3EDF5),
        foregroundColor: morado,
        elevation: 0,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: "Regresar",
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -105,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: morado.withOpacity(0.28),
                shape: BoxShape.circle,
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
                          color: morado,
                        ),
                      ),

                      SizedBox(height: 25),

                      // ALIAS
                      TextField(
                        controller: aliasController,
                        enabled: !claveVerificada,
                        decoration: InputDecoration(
                          labelText: "Alias",
                          prefixIcon: Icon(Icons.person),
                          filled: true,
                          fillColor: Color(0xFFFAF8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: borde.withOpacity(0.55),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: morado, width: 1.6),
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
                          labelText: "Clave de recuperación",
                          prefixIcon: Icon(Icons.vpn_key),
                          filled: true,
                          fillColor: Color(0xFFFAF8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: borde.withOpacity(0.55),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: morado, width: 1.6),
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
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : verificarClave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: morado,
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
                            labelText: "Nueva contraseña",
                            prefixIcon: Icon(Icons.lock),
                            filled: true,
                            fillColor: Color(0xFFFAF8FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: borde),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                color: borde.withOpacity(0.55),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: morado, width: 1.6),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        TextField(
                          controller: confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Confirmar contraseña",
                            prefixIcon: Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Color(0xFFFAF8FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: borde),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                color: borde.withOpacity(0.55),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: morado, width: 1.6),
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
                              backgroundColor: morado,
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
