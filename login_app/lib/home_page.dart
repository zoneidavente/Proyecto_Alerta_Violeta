import 'package:flutter/material.dart';
import 'emergencia_page.dart';
import 'reporte_page.dart';
import 'mapa_page.dart';
import 'notificaciones_page.dart';

class HomePage extends StatefulWidget {
  final String alias;

  HomePage({required this.alias});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color.fromARGB(255, 205, 182, 214);
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

              // CONTENIDO
              Column(
                children: [
                  // BARRA SUPERIOR
                  Container(
                    width: double.infinity,
                    height: 110,
                    padding: EdgeInsets.symmetric(horizontal: 18),

                    decoration: BoxDecoration(
                      color: moradoSuave.withOpacity(0.4),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        // BARRA ESTADO
                        Row(
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

                        SizedBox(height: 20),

                        // TÍTULO
                        Text(
                          "ALERTA VIOLETA",

                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // LOGO
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/logo.png",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 18);
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 25),

                  // TEXTO
                  Text(
                    "No estás sola, Puedes reportar situaciones\n"
                    "de acoso callejero de forma anónima y segura.\n"
                    "Tu voz importa.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 40),

                  // BOTÓN SOS
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EmergenciaPage(alias: widget.alias),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rojoBoton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Text(
                        "SOS",
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // BOTÓN REPORTE
                  SizedBox(
                    width: 200,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportePage(alias: widget.alias),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moradoSuave,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Text(
                        "Realizar Reporte",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

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

                  SizedBox(height: 50),
                ],
              ),
            ],
          ),
        ),
      ),
      //  BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;

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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: moradoIconos,
        unselectedItemColor: moradoIconos,
        backgroundColor: moradoSuave.withOpacity(0.7),

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
