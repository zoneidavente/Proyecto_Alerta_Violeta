import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'home_page.dart';
import 'notificaciones_page.dart';

class MapaPage extends StatefulWidget {
  final String alias;

  MapaPage({required this.alias});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  int currentIndex = 2;

  List reportes = [];

  Position? posicionActual;

  final MapController mapController = MapController();

  final LatLng posicionInicial = LatLng(3.4516, -76.5320);

  @override
  void initState() {
    super.initState();

    obtenerReportes();
    obtenerUbicacionActual();
  }

  // =====================================================
  // OBTENER REPORTES DEL BACKEND
  // =====================================================

  Future<void> obtenerReportes() async {
    try {
      var response = await http.get(
        Uri.parse("http://192.168.0.19:3000/reporte"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            reportes = data;
          });
        }
      }
    } catch (e) {
      print("Error obteniendo reportes: $e");
    }
  }

  // =====================================================
  // OBTENER UBICACIÓN ACTUAL
  // =====================================================

  Future<void> obtenerUbicacionActual() async {
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

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

      setState(() {
        posicionActual = posicion;
      });

      // MOVER EL MAPA A LA UBICACIÓN ACTUAL
      mapController.move(LatLng(posicion.latitude, posicion.longitude), 15);
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }

  // =====================================================
  // CALCULAR DISTANCIA ENTRE DOS PUNTOS
  // =====================================================

  double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // =====================================================
  // DETERMINAR NIVEL DE RIESGO
  // =====================================================

  String determinarNivelRiesgo(Map<String, dynamic> reporte) {
    if (reporte["latitud"] == null || reporte["longitud"] == null) {
      return "bajo";
    }

    double lat = (reporte["latitud"] as num).toDouble();

    double lon = (reporte["longitud"] as num).toDouble();

    int cantidadReportes = 0;

    // Radio aproximado de 500 metros
    for (var otroReporte in reportes) {
      if (otroReporte["latitud"] == null || otroReporte["longitud"] == null) {
        continue;
      }

      double otraLat = (otroReporte["latitud"] as num).toDouble();

      double otraLon = (otroReporte["longitud"] as num).toDouble();

      double distancia = calcularDistancia(lat, lon, otraLat, otraLon);

      if (distancia <= 500) {
        cantidadReportes++;
      }
    }

    // ============================================
    // CLASIFICACIÓN
    // ============================================

    if (cantidadReportes >= 6) {
      return "alto";
    }

    if (cantidadReportes >= 3) {
      return "medio";
    }

    return "bajo";
  }

  // =====================================================
  // COLOR SEGÚN NIVEL DE RIESGO
  // =====================================================

  Color colorRiesgo(String nivel) {
    switch (nivel) {
      case "alto":
        return Colors.red;

      case "medio":
        return Colors.yellow.shade700;

      case "bajo":
      default:
        return Colors.green;
    }
  }

  // =====================================================
  // CREAR CÍRCULOS DE ZONAS DE RIESGO
  // =====================================================

  List<CircleMarker> construirZonasRiesgo() {
    List<CircleMarker> zonas = [];

    for (var reporte in reportes) {
      if (reporte["latitud"] == null || reporte["longitud"] == null) {
        continue;
      }

      double lat = (reporte["latitud"] as num).toDouble();

      double lon = (reporte["longitud"] as num).toDouble();

      String nivel = determinarNivelRiesgo(reporte);

      Color color = colorRiesgo(nivel);

      zonas.add(
        CircleMarker(
          point: LatLng(lat, lon),

          radius: 500,

          useRadiusInMeter: true,

          color: color.withOpacity(0.20),

          borderColor: color.withOpacity(0.70),

          borderStrokeWidth: 2,
        ),
      );
    }

    return zonas;
  }

  // =====================================================
  // CREAR MARCADORES DE REPORTES
  // =====================================================

  List<Marker> construirMarcadoresReportes() {
    return reportes
        .where(
          (reporte) =>
              reporte["latitud"] != null && reporte["longitud"] != null,
        )
        .map<Marker>((reporte) {
          double lat = (reporte["latitud"] as num).toDouble();

          double lon = (reporte["longitud"] as num).toDouble();

          String nivel = determinarNivelRiesgo(reporte);

          Color color = colorRiesgo(nivel);

          return Marker(
            width: 50,
            height: 50,

            point: LatLng(lat, lon),

            child: GestureDetector(
              onTap: () {
                mostrarInformacionReporte(reporte, nivel);
              },

              child: Icon(Icons.warning_rounded, color: color, size: 35),
            ),
          );
        })
        .toList();
  }

  // =====================================================
  // MARCADOR DE UBICACIÓN ACTUAL
  // =====================================================

  List<Marker> construirMarcadorUbicacion() {
    if (posicionActual == null) {
      return [];
    }

    return [
      Marker(
        width: 60,
        height: 60,

        point: LatLng(posicionActual!.latitude, posicionActual!.longitude),

        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.25),
          ),

          child: Icon(Icons.my_location, color: Colors.blue, size: 35),
        ),
      ),
    ];
  }

  // =====================================================
  // MOSTRAR INFORMACIÓN DEL REPORTE
  // =====================================================

  void mostrarInformacionReporte(dynamic reporte, String nivel) {
    showModalBottomSheet(
      context: context,

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Zona de riesgo",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),

              SizedBox(height: 15),

              Text(
                "Nivel: ${nivel.toUpperCase()}",

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorRiesgo(nivel),
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Tipo de acoso: "
                "${reporte["tipo_acoso"] ?? "No disponible"}",
              ),

              SizedBox(height: 10),

              Text(
                "Ubicación: "
                "${reporte["direccion"] ?? "No disponible"}",
              ),

              SizedBox(height: 10),

              Text(
                "Descripción: "
                "${reporte["descripcion"] ?? "No disponible"}",
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // IR A MI UBICACIÓN
  // =====================================================

  void volverAMiUbicacion() {
    if (posicionActual == null) {
      obtenerUbicacionActual();
      return;
    }

    mapController.move(
      LatLng(posicionActual!.latitude, posicionActual!.longitude),
      15,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);

    Color moradoSuave = Color(0xFFAB8FB8);

    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);

    return Scaffold(
      backgroundColor: fondo,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // =========================================
              // CÍRCULO OSCURO
              // =========================================
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

              // =========================================
              // CÍRCULO CLARO
              // =========================================
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

              // =========================================
              // BARRA SUPERIOR
              // =========================================
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

              // =========================================
              // CONTENIDO
              // =========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(height: 60),

                    // TÍTULO
                    Center(
                      child: Text(
                        "Zonas de Riesgo",

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(height: 80),

                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),

                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 221, 198, 226),

                        borderRadius: BorderRadius.circular(4),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,

                        children: [
                          Text(
                            "Bajo",

                            style: TextStyle(
                              color: Colors.green,

                              fontWeight: FontWeight.bold,

                              fontSize: 22,
                            ),
                          ),

                          Text(
                            "Medio",

                            style: TextStyle(
                              color: Colors.yellow.shade700,

                              fontWeight: FontWeight.bold,

                              fontSize: 22,
                            ),
                          ),

                          Text(
                            "Alto",

                            style: TextStyle(
                              color: Colors.red,

                              fontWeight: FontWeight.bold,

                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 50),

                    // =====================================
                    // MAPA
                    // =====================================
                    Container(
                      width: double.infinity,

                      height: 250,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Stack(
                          children: [
                            // MAPA
                            FlutterMap(
                              mapController: mapController,

                              options: MapOptions(
                                initialCenter: posicionInicial,

                                initialZoom: 13,
                              ),

                              children: [
                                // MAPA OPENSTREETMAP
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                                  userAgentPackageName: 'com.alertavioleta.app',
                                ),

                                // ZONAS DE RIESGO
                                CircleLayer(circles: construirZonasRiesgo()),

                                // MARCADORES
                                MarkerLayer(
                                  markers: [
                                    ...construirMarcadoresReportes(),

                                    ...construirMarcadorUbicacion(),
                                  ],
                                ),
                              ],
                            ),

                            // =================================
                            // BOTÓN MI UBICACIÓN
                            // =================================
                            Positioned(
                              right: 10,
                              bottom: 10,

                              child: FloatingActionButton(
                                mini: true,

                                backgroundColor: Colors.white,

                                onPressed: volverAMiUbicacion,

                                child: Icon(
                                  Icons.my_location,

                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // =========================================
      // BOTTOM NAVIGATION
      // =========================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        selectedItemColor: moradoIconos,

        unselectedItemColor: moradoIconos,

        backgroundColor: moradoSuave.withOpacity(0.3),

        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == currentIndex) {
            return;
          }

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
