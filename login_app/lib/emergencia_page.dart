import 'package:flutter/material.dart';
import 'home_page.dart';
import 'mapa_page.dart';
import 'notificaciones_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'api_config.dart';
import 'app_session.dart';

class EmergenciaPage extends StatefulWidget {
  final String alias;
  final String role;

  EmergenciaPage({required this.alias, required this.role});
  @override
  State<EmergenciaPage> createState() => _EmergenciaPageState();
}

class _EmergenciaPageState extends State<EmergenciaPage> {
  double? latitud;
  double? longitud;

  String direccion = "";
  int currentIndex = 0;

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

  Future<void> enviarAlertaSOS() async {
    await obtenerUbicacion();

    try {
      var response = await http.post(
        apiUri('/emergencia'),

        headers: AppSession.authHeaders(json: true),

        body: jsonEncode({
          "latitud": latitud,

          "longitud": longitud,

          "direccion": direccion,
        }),
      );

      var data = jsonDecode(response.body);

      if (data["success"]) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Alerta SOS enviada")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No se pudo enviar")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF5EFF7);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);
    Color rojo = Color(0xFFE8646E);
    Color moradoSuave = Color(0xFFAB8FB8);

    return Scaffold(
      backgroundColor: fondo,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Stack(
              children: [
                // CÍRCULO OSCURO
                Positioned(
                  top: -290,
                  left: -130,
                  child: Transform.translate(
                    offset: Offset(-90, -90),
                    child: Container(
                      width: 800,
                      height: 420,
                      decoration: BoxDecoration(
                        color: moradoSuave,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // CÍRCULO CLARO
                Positioned(
                  top: -180,
                  left: -100,
                  child: Transform.translate(
                    offset: Offset(-98, -98),
                    child: Container(
                      width: 400,
                      height: 390,
                      decoration: BoxDecoration(
                        color: moradoSuave.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // BARRA SUPERIOR
                Container(
                  width: double.infinity,
                  height: 110,
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(color: rojo),
                ),

                Positioned.fill(
                  child: Center(
                    child: Text(
                      "¡Alerta de emergencia!",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 8, 8, 8),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // TEXTO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),

              child: Text(
                "No estás sola. Puedes reportar situaciones\n"
                "de acoso callejero de forma anónima y segura.\n"
                "Tu voz importa.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),

            SizedBox(height: 95),

            // BOTÓN ALERTA
            Spacer(),

            // TEXTO FINAL
            Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: Text(
                "Tu ubicación será enviada de forma automática,\n"
                "no se registran datos personales.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          if (index == currentIndex) return;

          Widget page;

          switch (index) {
            case 0:
              page = HomePage(alias: widget.alias, role: widget.role);
              break;

            case 1:
              page = NotificacionesPage(alias: widget.alias, role: widget.role);
              break;

            case 2:
              page = MapaPage(alias: widget.alias, role: widget.role);
              break;

            default:
              page = HomePage(alias: widget.alias, role: widget.role);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: moradoIconos,
        unselectedItemColor: moradoIconos,

        backgroundColor: moradoSuave.withOpacity(0.3),

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notificaciones",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Mapa"),

          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: "Ayuda",
          ),
        ],
      ),
    );
  }
}
