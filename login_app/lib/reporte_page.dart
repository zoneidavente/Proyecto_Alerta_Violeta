import 'package:flutter/material.dart';
import 'home_page.dart';
import 'mapa_page.dart';
import 'notificaciones_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class ReportePage extends StatefulWidget {
  final String alias;

  ReportePage({required this.alias});

  @override
  State<ReportePage> createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {
  int currentIndex = 1;

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

    // OBTENER UBICACIÓN
    await obtenerUbicacion();

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
        Uri.parse("http://192.168.0.19:3000/reporte"),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode(bodyData),
      );

      print(response.body);

      var data = jsonDecode(response.body);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reporte enviado correctamente")),
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
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color(0xFFAB8FB8);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);
    Color rojoBoton = Color(0xFFE35D6A);

    return Scaffold(
      backgroundColor: fondo,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(height: 60),

                    // TÍTULO
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              "Reporte Detallado",

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

                    SizedBox(height: 50),

                    // TIPO DE ACOSO
                    Text(
                      "Tipo de acoso",

                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: tipoAcoso,

                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                        ),
                      ),

                      hint: Text("Selecciona"),

                      items: tipos.map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          tipoAcoso = value;
                        });
                      },
                    ),

                    SizedBox(height: 25),

                    // DESCRIPCIÓN
                    Container(
                      height: 110,

                      decoration: BoxDecoration(
                        color: moradoSuave.withOpacity(0.2),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: TextField(
                        controller: descripcionController,

                        maxLines: 5,

                        decoration: InputDecoration(
                          hintText: "Descripción (Opcional)",

                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),

                          border: InputBorder.none,

                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // BOTÓN ENVIAR
                    Center(
                      child: SizedBox(
                        width: 320,
                        height: 60,

                        child: ElevatedButton(
                          onPressed: enviarReporte,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: rojoBoton,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),

                          child: Text(
                            "ENVIAR REPORTE",

                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // TEXTO FINAL
                    Center(
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

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
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
