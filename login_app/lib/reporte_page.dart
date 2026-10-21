import 'package:flutter/material.dart';
import 'home_page.dart';
import 'mapa_page.dart';
import 'notificaciones_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'api_config.dart';

class ReportePage extends StatefulWidget {
  final String alias;
  final String role;

  ReportePage({required this.alias, required this.role});

  @override
  State<ReportePage> createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {
  int currentIndex = 1;
  bool compartirUbicacion = true;

  String? tipoAcoso;

  double? latitud;
  double? longitud;

  String direccion = "";

  final List<String> tipos = [
    "Verbal",
    "Físico",
    "Visual",
    "Persecución",
    "Otro",
  ];

  final TextEditingController descripcionController = TextEditingController();

  // OBTENER UBICACIÓN
  Future<void> obtenerUbicacion() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    servicioHabilitado = await Geolocator.isLocationServiceEnabled();

    if (!servicioHabilitado) {
      return;
    }

    permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();

      if (permiso == LocationPermission.denied) {
        return;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return;
    }

    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitud = posicion.latitude;
    longitud = posicion.longitude;

    // DIRECCIÓN REAL CON NOMINATIM
    final url =
        "https://nominatim.openstreetmap.org/reverse"
        "?format=json"
        "&lat=$latitud"
        "&lon=$longitud";

    final response = await http.get(
      Uri.parse(url),

      headers: {"User-Agent": "alerta_violeta_app"},
    );

    final data = jsonDecode(response.body);

    direccion = data["display_name"] ?? "Dirección no encontrada";
  }

  // ENVIAR REPORTE
  Future<void> enviarReporte() async {
    if (tipoAcoso == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecciona el tipo de acoso")));

      return;
    }

    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("La descripción es obligatoria")));

      return;
    }

    if (compartirUbicacion) {
      await obtenerUbicacion();
    } else {
      latitud = null;
      longitud = null;
      direccion = "";
    }

    try {
      Map<String, dynamic> bodyData = {
        "alias": widget.alias,

        "tipo_acoso": tipoAcoso,

        "descripcion": descripcionController.text.trim(),

        "latitud": latitud,

        "longitud": longitud,

        "direccion": direccion,
      };

      print(jsonEncode(bodyData));

      var response = await http.post(
        apiUri('/reporte'),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode(bodyData),
      );

      print(response.body);

      var data = jsonDecode(response.body);

      if (data["success"]) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            });

            return Dialog(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        "Reporte enviado correctamente",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        descripcionController.clear();

        setState(() {
          tipoAcoso = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
      }
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }
  }

  @override
  void dispose() {
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fondo = Color(0xFFF3EDF5);
    const morado = Color(0xFF3C154E);
    const moradoSuave = Color(0xFFEFE2FA);
    const borde = Color(0xFFD9C6E8);
    const rojo = Color(0xFFFF5B70);
    const circuloMorado = Color(0xFFAB8FB8);

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -290,
              left: -130,
              child: Transform.translate(
                offset: const Offset(-90, -90),
                child: Container(
                  width: 800,
                  height: 420,
                  decoration: const BoxDecoration(
                    color: circuloMorado,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -180,
              left: -100,
              child: Transform.translate(
                offset: const Offset(-98, -98),
                child: Container(
                  width: 400,
                  height: 390,
                  decoration: BoxDecoration(
                    color: circuloMorado.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 26,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: morado.withValues(alpha: 0.09),
                                      blurRadius: 22,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Center(
                                      child: Text(
                                        "Reporte detallado",
                                        style: TextStyle(
                                          color: Color(0xFF1F1F1F),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Tipo de situación",
                                      style: TextStyle(
                                        color: morado,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      initialValue: tipoAcoso,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        hintText: "Selecciona una situación",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: borde,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: morado,
                                          ),
                                        ),
                                      ),
                                      items: tipos.map((tipo) {
                                        return DropdownMenuItem(
                                          value: tipo,
                                          child: Text(tipo),
                                        );
                                      }).toList(),
                                      onChanged: (value) =>
                                          setState(() => tipoAcoso = value),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Describe lo ocurrido",
                                      style: TextStyle(
                                        color: morado,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: descripcionController,
                                      maxLength: 500,
                                      minLines: 3,
                                      maxLines: 4,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText:
                                            "Escribe aquí los detalles...",
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF8D8196),
                                          fontSize: 12,
                                        ),
                                        counterStyle: const TextStyle(
                                          color: Color(0xFF806D8B),
                                          fontSize: 9,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              12,
                                              10,
                                              12,
                                              4,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: borde,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: morado,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: moradoSuave,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: morado,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Compartir mi ubicación actual",
                                                  style: TextStyle(
                                                    color: morado,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  "Solo se incluirá en este reporte.",
                                                  style: TextStyle(
                                                    color: Color(0xFF806D8B),
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: compartirUbicacion,
                                            activeThumbColor: Colors.white,
                                            activeTrackColor: Color(0xFF843AC0),
                                            onChanged: (value) => setState(
                                              () => compartirUbicacion = value,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.maybePop(context),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: morado,
                                              side: const BorderSide(
                                                color: Color(0xFF9149C6),
                                              ),
                                              minimumSize: const Size(0, 40),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: const Text("Cancelar"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: enviarReporte,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: rojo,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(0, 40),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text("Enviar reporte"),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          if (widget.role == "usuario") {
            // USUARIO
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomePage(alias: widget.alias, role: widget.role),
                  ),
                );
                break;

              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificacionesPage(
                      alias: widget.alias,
                      role: widget.role,
                    ),
                  ),
                );
                break;

              case 2:
                // Ayuda
                break;
            }
          } else {
            // ADMINISTRADOR
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomePage(alias: widget.alias, role: widget.role),
                  ),
                );
                break;

              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MapaPage(alias: widget.alias, role: widget.role),
                  ),
                );
                break;

              case 2:
                // Ayuda
                break;
            }
          }
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF3C154E),
        unselectedItemColor: const Color(0xFF3C154E),
        backgroundColor: circuloMorado.withOpacity(0.7),

        items: widget.role == "usuario"
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Inicio",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: "Notificaciones",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent),
                  label: "Ayuda",
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Inicio",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.location_on),
                  label: "Mapa",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent),
                  label: "Ayuda",
                ),
              ],
      ),
    );
  }
}
