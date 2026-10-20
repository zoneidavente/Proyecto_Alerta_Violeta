import 'package:flutter/material.dart';
import 'home_page.dart';
import 'mapa_page.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'dart:convert';

class NotificacionesPage extends StatefulWidget {
  final String alias;
  final String role;

  NotificacionesPage({required this.alias, required this.role});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List notificaciones = [];

  int currentIndex = 1;

  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? timerNotificaciones;

  Set<String> idsNotificaciones = {};
  bool primeraCarga = true;
  String filtroActual = "Todas";

  String obtenerTiempo(String fecha) {
    DateTime fechaReporte = DateTime.parse(fecha);

    return timeago.format(fechaReporte, locale: "es");
  }

  Future<void> cargarNotificaciones() async {
    try {
      // REPORTES
      var reporteResponse = await http.get(
        Uri.parse("http://192.168.20.32:3000/reporte"),
      );

      // ALERTAS SOS
      var emergenciaResponse = await http.get(
        Uri.parse("http://192.168.20.32:3000/emergencia"),
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

      // Crear identificadores para detectar nuevas notificaciones
      Set<String> nuevosIds = todas.map((item) {
        return item["_id"]?.toString() ?? item["fecha"].toString();
      }).toSet();

      // Si no es la primera carga y apareció una nueva notificación
      if (!primeraCarga) {
        bool hayNueva = nuevosIds.difference(idsNotificaciones).isNotEmpty;

        if (hayNueva) {
          await audioPlayer.play(AssetSource('alertaSonido.mp3'));
        }
      }

      setState(() {
        notificaciones = todas;
      });

      idsNotificaciones = nuevosIds;
      primeraCarga = false;
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    timeago.setLocaleMessages('es', timeago.EsMessages());

    cargarNotificaciones();

    timerNotificaciones = Timer.periodic(const Duration(seconds: 5), (timer) {
      cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    timerNotificaciones?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildFiltro(String label) {
    final bool seleccionado = filtroActual == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            filtroActual = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: seleccionado
                ? Color(0xFFB68BC7)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado ? Color(0xFFB68BC7) : Color(0xFFE5D9ED),
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.white : Color(0xFF5B3B69),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color(0xFFAB8FB8);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);

    List notificacionesFiltradas = [];
    if (filtroActual == "Todas") {
      notificacionesFiltradas = notificaciones;
    } else if (filtroActual == "SOS") {
      notificacionesFiltradas = notificaciones
          .where((item) => item["categoria"] == "SOS")
          .toList();
    } else {
      notificacionesFiltradas = notificaciones
          .where((item) => item["categoria"] == "Reporte")
          .toList();
    }

    return Scaffold(
      backgroundColor: fondo,
      body: Stack(
        children: [
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
          Container(
            width: double.infinity,
            height: 110,
            padding: EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(color: moradoSuave.withOpacity(0.4)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Center(
                    child: Text(
                      "Notificaciones",
                      style: TextStyle(
                        fontSize: 21,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 34),
                  Row(
                    children: [
                      _buildFiltro("Todas"),
                      _buildFiltro("SOS"),
                      _buildFiltro("Reportes"),
                    ],
                  ),
                  SizedBox(height: 18),
                  Expanded(
                    child: notificacionesFiltradas.isEmpty
                        ? Center(
                            child: Text(
                              "No hay notificaciones disponibles",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: notificacionesFiltradas.length,
                            separatorBuilder: (_, __) => SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = notificacionesFiltradas[index];
                              final bool esSos = item["categoria"] == "SOS";
                              final String etiqueta = esSos
                                  ? "Alerta de emergencia"
                                  : "Reporte de acoso";
                              final String titulo = esSos
                                  ? "SOS enviado"
                                  : (item["tipo_acoso"] ?? "Persecución");
                              final String descripcion = esSos
                                  ? "Ubicación compartida"
                                  : (item["descripcion"] ??
                                        "Una persona me sigue");
                              final String alias =
                                  item["alias"]?.toString().trim().isNotEmpty ==
                                      true
                                  ? item["alias"].toString().trim()
                                  : "Usuario";
                              final String direccion =
                                  item["direccion"] ?? "Carrera 42C, Cali";
                              final String tiempo = obtenerTiempo(
                                item["fecha"],
                              );
                              final colorAlerta = esSos
                                  ? Colors.red.shade700
                                  : Colors.orange.shade800;
                              final colorFondo = esSos
                                  ? const Color(0xFFFFF5F5)
                                  : const Color(0xFFFFFBF0);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colorFondo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorAlerta.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colorAlerta.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        esSos
                                            ? Icons.sos
                                            : Icons.warning_amber_rounded,
                                        color: colorAlerta,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  titulo,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1F1F1F),
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                tiempo,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontFamily: 'Poppins',
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "$etiqueta · Alias: $alias",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF4E4E4E),
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          if (!esSos)
                                            Text(
                                              descripcion,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF666666),
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 13,
                                                color: colorAlerta,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  direccion,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontFamily: 'Poppins',
                                                    color: Color(0xFF555555),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (widget.role == "usuario") {
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
                break;
            }
          } else {
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
                break;
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: moradoIconos,
        unselectedItemColor: moradoIconos,
        backgroundColor: moradoSuave.withOpacity(0.7),
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
