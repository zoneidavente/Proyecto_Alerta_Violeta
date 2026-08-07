import 'package:flutter/material.dart';
import 'home_page.dart';
import 'mapa_page.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

import 'dart:convert';

class NotificacionesPage extends StatefulWidget {
  final String alias;

  NotificacionesPage({required this.alias});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List notificaciones = [];

  int currentIndex = 1;

  String obtenerTiempo(String fecha) {
    DateTime fechaReporte = DateTime.parse(fecha);

    return timeago.format(fechaReporte, locale: "es");
  }

  Future<void> cargarNotificaciones() async {
    try {
      // REPORTES
      var reporteResponse = await http.get(
        Uri.parse("http://192.168.0.19:3000/reporte"),
      );

      // ALERTAS SOS
      var emergenciaResponse = await http.get(
        Uri.parse("http://192.168.0.19:3000/emergencia"),
      );

      List reportes = jsonDecode(reporteResponse.body);

      List emergencias = jsonDecode(emergenciaResponse.body);

      // AGREGAR TIPO A CADA ELEMENTO
      reportes = reportes.map((e) {
        e["categoria"] = "Reporte";
        return e;
      }).toList();

      emergencias = emergencias.map((e) {
        e["categoria"] = "SOS";
        return e;
      }).toList();

      List todas = [...reportes, ...emergencias];

      // ORDENAR POR FECHA MÁS RECIENTE
      todas.sort((a, b) {
        DateTime fechaA = DateTime.parse(a["fecha"]);

        DateTime fechaB = DateTime.parse(b["fecha"]);

        return fechaB.compareTo(fechaA);
      });

      setState(() {
        notificaciones = todas;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());

    cargarNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color(0xFFAB8FB8);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);

    return Scaffold(
      backgroundColor: fondo,

      body: Stack(
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
            decoration: BoxDecoration(color: moradoSuave.withOpacity(0.4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "7:00",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt, size: 18),
                    SizedBox(width: 5),
                    Icon(Icons.wifi, size: 18),
                    SizedBox(width: 5),
                    Icon(Icons.battery_full, size: 18),
                  ],
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),

              child: Column(
                children: [
                  SizedBox(height: 60),

                  // TÍTULO
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "Notificaciones",

                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 20),
                    ],
                  ),

                  SizedBox(height: 90),

                  // LISTA DE ALERTAS
                  Expanded(
                    child: Expanded(
                      child: notificaciones.isEmpty
                          ? Center(
                              child: Text(
                                "No hay notificaciones disponibles",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: notificaciones.length,

                              itemBuilder: (context, index) {
                                var item = notificaciones[index];

                                return Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  padding: EdgeInsets.all(15),

                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            item["categoria"] == "SOS"
                                                ? Icons.sos
                                                : Icons.warning_amber_rounded,

                                            color: item["categoria"] == "SOS"
                                                ? Colors.red
                                                : Colors.orange,
                                          ),

                                          SizedBox(width: 10),

                                          Expanded(
                                            child: Text(
                                              item["categoria"] == "SOS"
                                                  ? "Alerta de emergencia"
                                                  : " Reporte de acoso: ${item["tipo_acoso"]}",

                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 10),

                                      Text(
                                        item["descripcion"] ?? "Alerta enviada",

                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),

                                      SizedBox(height: 10),

                                      Text(
                                        item["direccion"] ??
                                            "Ubicación no disponible",

                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),

                                      SizedBox(height: 8),

                                      Text(
                                        "Alias: ${item["alias"]}",

                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color.fromARGB(123, 0, 0, 0),
                                        ),
                                      ),
                                      SizedBox(height: 8),

                                      Text(
                                        " ${obtenerTiempo(item["fecha"])}",

                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color.fromARGB(
                                            255,
                                            110,
                                            109,
                                            109,
                                          ),
                                          fontFamily: 'Poppins',
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // TEXTO INFERIOR
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
          ),
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: moradoIconos,
        unselectedItemColor: moradoIconos,

        backgroundColor: moradoSuave.withOpacity(0.3),

        onTap: (index) {
          Widget page;

          switch (index) {
            case 0:
              page = HomePage(alias: widget.alias);
              break;

            case 1:
              page = NotificacionesPage(alias: widget.alias);
              break;

            case 2:
              page = MapaPage(alias: widget.alias);
              break;

            default:
              page = HomePage(alias: widget.alias);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },

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
