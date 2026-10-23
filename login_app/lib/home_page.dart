import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'reporte_page.dart';
import 'mapa_page.dart';
import 'notificaciones_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'administrar_reportes_page.dart';
import 'api_config.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  final String alias;
  final String role;

  HomePage({required this.alias, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<dynamic> reportesAdmin = [];
  List<dynamic> alertasAdmin = [];
  bool cargandoResumen = true;

  @override
  void initState() {
    super.initState();
    unawaited(AppNotificationService.instance.start(widget.alias));
    if (widget.role == "administrador") {
      cargarResumenAdmin();
    }
  }

  Future<void> cargarResumenAdmin() async {
    try {
      final respuestas = await Future.wait([
        http.get(apiUri('/reporte')),
        http.get(apiUri('/emergencia')),
      ]);

      if (respuestas.every((respuesta) => respuesta.statusCode == 200)) {
        if (!mounted) return;
        setState(() {
          reportesAdmin = jsonDecode(respuestas[0].body);
          alertasAdmin = jsonDecode(respuestas[1].body);
          cargandoResumen = false;
        });
      } else if (mounted) {
        setState(() => cargandoResumen = false);
      }
    } catch (_) {
      if (mounted) setState(() => cargandoResumen = false);
    }
  }

  int _contarEstado(List<dynamic> elementos, Set<String> estados) {
    return elementos.where((elemento) {
      final estado =
          elemento["estado"]?.toString().toLowerCase() ?? "pendiente";
      return estados.contains(estado);
    }).length;
  }

  List<dynamic> get _casosAdmin => [...reportesAdmin, ...alertasAdmin];

  List<Map<String, dynamic>> _actividadReciente() {
    final actividad = <Map<String, dynamic>>[
      ...reportesAdmin.map((reporte) => {"tipo": "Reporte", "dato": reporte}),
      ...alertasAdmin.map((alerta) => {"tipo": "Alerta SOS", "dato": alerta}),
    ];
    actividad.sort((a, b) {
      final fechaA = DateTime.tryParse(a["dato"]["fecha"]?.toString() ?? "");
      final fechaB = DateTime.tryParse(b["dato"]["fecha"]?.toString() ?? "");
      return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
    });
    return actividad.take(4).toList();
  }

  String _formatearFecha(dynamic valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? "");
    if (fecha == null) return "Fecha no disponible";
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, "0");
    final mes = local.month.toString().padLeft(2, "0");
    final hora = local.hour.toString().padLeft(2, "0");
    final minuto = local.minute.toString().padLeft(2, "0");
    return "$dia/$mes/${local.year} · $hora:$minuto";
  }

  Widget _construirPanelAdmin() {
    const morado = Color(0xFF54216F);
    const violeta = Color(0xFF8150A8);
    const rojo = Color(0xFFE65362);
    const naranja = Color(0xFFE18A13);
    final ancho = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ancho < 600 ? 16 : 30,
                20,
                ancho < 600 ? 20 : 34,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Panel de administración",
                        style: TextStyle(
                          color: Color(0xFF321443),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Resumen general",
                        style: TextStyle(
                          color: Color(0xFF816A91),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columnas = constraints.maxWidth >= 1100
                              ? 4
                              : constraints.maxWidth >= 280
                              ? 2
                              : 1;
                          final tarjetas = <Widget>[
                            _tarjetaResumen(
                              "Alertas activas",
                              cargandoResumen
                                  ? "—"
                                  : "${_contarEstado(alertasAdmin, {"pendiente", "en revisión"})}",
                              Icons.notifications_active_outlined,
                              rojo,
                              compacta: columnas < 4,
                            ),
                            _tarjetaResumen(
                              "Reportes pendientes",
                              cargandoResumen
                                  ? "—"
                                  : "${_contarEstado(_casosAdmin, {"pendiente"})}",
                              Icons.description_outlined,
                              naranja,
                              compacta: columnas < 4,
                            ),
                            _tarjetaResumen(
                              "Casos atendidos",
                              cargandoResumen
                                  ? "—"
                                  : "${_contarEstado(_casosAdmin, {"atendido", "cerrado"})}",
                              Icons.task_alt,
                              violeta,
                              compacta: columnas < 4,
                            ),
                            _tarjetaResumen(
                              "Casos recibidos",
                              cargandoResumen ? "—" : "${_casosAdmin.length}",
                              Icons.assessment_outlined,
                              const Color(0xFF159A9A),
                              compacta: columnas < 4,
                            ),
                          ];
                          final espacio = columnas == 1 ? 10.0 : 14.0;
                          return Wrap(
                            spacing: espacio,
                            runSpacing: espacio,
                            children: tarjetas
                                .map(
                                  (tarjeta) => SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            espacio * (columnas - 1)) /
                                        columnas,
                                    child: tarjeta,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (ancho < 850)
                        Column(
                          children: [
                            _bloqueActividad(morado),
                            const SizedBox(height: 14),
                            _botonGestionReportes(morado),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _bloqueActividad(morado)),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _botonGestionReportes(morado),
                            ),
                          ],
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

  Widget _tarjetaResumen(
    String titulo,
    String valor,
    IconData icono,
    Color color, {
    bool compacta = false,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: compacta ? 92 : 132),
      padding: EdgeInsets.all(compacta ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A321443),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compacta ? 40 : 58,
            height: compacta ? 40 : 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: compacta ? 21 : 29),
          ),
          SizedBox(width: compacta ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Color(0xFF39274A),
                    fontSize: compacta ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    color: color,
                    fontSize: compacta ? 23 : 29,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloqueActividad(Color morado) {
    final actividades = _actividadReciente();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A321443),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Actividad reciente",
            style: TextStyle(
              color: Color(0xFF321443),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(height: 18, color: Color(0xFFEFEAF3)),
          if (cargandoResumen)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (actividades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                "Todavía no hay actividad registrada.",
                style: TextStyle(color: Color(0xFF816A91), fontSize: 13),
              ),
            )
          else
            ...actividades.map((actividad) {
              final esAlerta = actividad["tipo"] == "Alerta SOS";
              final dato = actividad["dato"];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 3),
                dense: true,
                leading: CircleAvatar(
                  radius: 21,
                  backgroundColor: (esAlerta ? const Color(0xFFE65362) : morado)
                      .withValues(alpha: 0.1),
                  child: Icon(
                    esAlerta ? Icons.phone_in_talk : Icons.description,
                    color: esAlerta ? const Color(0xFFE65362) : morado,
                    size: 20,
                  ),
                ),
                title: Text(
                  esAlerta ? "Alerta SOS" : "Reporte recibido",
                  style: const TextStyle(
                    color: Color(0xFF39274A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "${dato["alias"] ?? "Usuario"} · ${_formatearFecha(dato["fecha"])}",
                  style: const TextStyle(
                    color: Color(0xFF816A91),
                    fontSize: 11,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: morado, size: 21),
              );
            }),
        ],
      ),
    );
  }

  Widget _botonGestionReportes(Color morado) {
    final pendientes = _contarEstado(_casosAdmin, {"pendiente"});
    final revision = _contarEstado(_casosAdmin, {"en revisión", "en_revision"});
    final atendidos = _contarEstado(_casosAdmin, {"atendido", "cerrado"});
    final total = _casosAdmin.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A321443),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Casos por estado",
            style: TextStyle(
              color: Color(0xFF321443),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: CustomPaint(
                  painter: _EstadosPainter(
                    pendientes: pendientes,
                    revision: revision,
                    atendidos: atendidos,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cargandoResumen ? "—" : "$total",
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF321443),
                          ),
                        ),
                        const Text(
                          "casos",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF816A91),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _itemEstado(
                      "Pendientes",
                      pendientes,
                      const Color(0xFFFFAA27),
                    ),
                    const SizedBox(height: 13),
                    _itemEstado(
                      "En revisión",
                      revision,
                      const Color(0xFF8150A8),
                    ),
                    const SizedBox(height: 13),
                    _itemEstado(
                      "Atendidos",
                      atendidos,
                      const Color(0xFF159A70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdministrarReportesPage(
                    alias: widget.alias,
                    role: widget.role,
                  ),
                ),
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text("Gestionar reportes"),
              style: FilledButton.styleFrom(
                backgroundColor: morado,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemEstado(String titulo, int valor, Color color) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          titulo,
          style: const TextStyle(color: Color(0xFF54465F), fontSize: 12),
        ),
      ),
      Text(
        "$valor",
        style: const TextStyle(
          color: Color(0xFF321443),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Future<void> enviarAlertaSOS() async {
    double? latitud;
    double? longitud;
    String direccion = "";

    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        _mostrarMensajeSOS(
          "Activa la ubicación de tu dispositivo para enviar la alerta.",
        );
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();

        if (permiso == LocationPermission.denied) {
          _mostrarMensajeSOS(
            "No se pudo obtener tu ubicación. La alerta no fue enviada.",
          );
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        _mostrarMensajeSOS(
          "El permiso de ubicación está desactivado. "
          "Actívalo en la configuración del dispositivo.",
        );
        return;
      }

      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitud = posicion.latitude;
      longitud = posicion.longitude;

      // Obtener dirección
      final url =
          "https://nominatim.openstreetmap.org/reverse"
          "?format=json"
          "&lat=$latitud"
          "&lon=$longitud";

      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "alerta_violeta_app"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        direccion = data["display_name"] ?? "Dirección no encontrada";
      }

      // ENVIAR ALERTA AL BACKEND
      final respuesta = await http.post(
        apiUri('/emergencia'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alias": widget.alias,
          "latitud": latitud,
          "longitud": longitud,
          "direccion": direccion,
        }),
      );

      final data = jsonDecode(respuesta.body);

      if (data["success"]) {
        _mostrarMensajeSOS(
          "La alerta quedó registrada y tu ubicación fue compartida con la red de apoyo.",
          enviada: true,
        );
      } else {
        _mostrarMensajeSOS(
          "No se pudo enviar la alerta. Inténtalo nuevamente.",
        );
      }
    } catch (e) {
      print(e);

      _mostrarMensajeSOS("Ocurrió un error al enviar la alerta.");
    }
  }

  void _mostrarMensajeSOS(String mensaje, {bool enviada = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final ahora = DateTime.now();
        final hora =
            "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          contentPadding: EdgeInsets.fromLTRB(20, 24, 20, 8),
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: null,
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: enviada ? Color(0xFFFFE7EA) : Color(0xFFF3EDF5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      enviada ? Icons.check_circle : Icons.warning_rounded,
                      size: 52,
                      color: enviada ? Color(0xFFE35D6A) : Color(0xFF6B3A82),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    enviada ? "Alerta SOS enviada" : "Alerta SOS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3C154E),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (enviada) ...[
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3EAF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Color(0xFF6B3A82),
                          ),
                          SizedBox(width: 7),
                          Text(
                            "Enviada a las $hora",
                            style: TextStyle(
                              color: Color(0xFF6B3A82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                  ] else
                    SizedBox(height: 14),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF40364A),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  if (enviada) ...[
                    SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5EDF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF6B2C91)),
                          SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 24,
                            color: Color(0xFFD9C9E0),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Ubicación compartida",
                              style: TextStyle(
                                color: Color(0xFF54236F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFEEF0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_rounded, color: Color(0xFFE35D6A)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Si estás en peligro inmediato, busca un lugar seguro y contacta a los servicios de emergencia.",
                              style: TextStyle(
                                color: Color(0xFF40364A),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B2C91),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "Volver al inicio",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color(0xFFAB8FB8);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);
    Color rojoBoton = Color(0xFFE35D6A);

    return Scaffold(
      backgroundColor: fondo,

      body: widget.role == "administrador"
          ? _construirPanelAdmin()
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final escala = (constraints.maxHeight / 520).clamp(0.5, 1.0);
                  return Stack(
                    fit: StackFit.expand,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // BARRA SUPERIOR
                          Container(
                            width: double.infinity,
                            height: 130 * escala,
                            padding: EdgeInsets.symmetric(horizontal: 18),

                            decoration: BoxDecoration(
                              color: moradoSuave.withOpacity(0.4),
                            ),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                // TÍTULO
                                Text(
                                  "ALERTA VIOLETA",

                                  style: TextStyle(
                                    fontSize: 24 * escala,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // LOGO
                          Container(
                            width: 90 * escala,
                            height: 90 * escala,
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

                          // TEXTO
                          Text(
                            "No estás sola, puedes reportar situaciones\n"
                            "de acoso callejero de forma anónima y segura.\n"
                            "Tu voz importa.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11 * escala,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),

                          // BOTÓN SOS
                          if (widget.role == "usuario")
                            SizedBox(
                              width: 130 * escala,
                              height: 130 * escala,
                              child: Container(
                                padding: EdgeInsets.all(8 * escala),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFE1E6),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    ///print("SOS DEL HOME FUNCIONANDO");///
                                    enviarAlertaSOS();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rojoBoton,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: CircleBorder(),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_active_outlined,
                                        size: 26 * escala,
                                      ),
                                      SizedBox(height: 2 * escala),
                                      Text(
                                        "SOS",
                                        style: TextStyle(
                                          fontSize: 25 * escala,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Enviar alerta\ninmediata",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9 * escala,
                                          fontFamily: 'Poppins',
                                          height: 1.1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // BOTÓN REPORTE
                          if (widget.role == "usuario")
                            SizedBox(
                              width: 210 * escala,
                              height: 38 * escala,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportePage(
                                        alias: widget.alias,
                                        role: widget.role,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Color(0xFF8150A8),
                                  side: BorderSide(
                                    color: Color(0xFF8150A8),
                                    width: 1.5,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * escala,
                                  ),
                                  shape: StadiumBorder(),
                                ),
                                icon: Icon(
                                  Icons.description_outlined,
                                  size: 16 * escala,
                                ),
                                label: Text(
                                  "Crear reporte detallado",
                                  style: TextStyle(
                                    fontSize: 10 * escala,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          // TEXTO FINAL
                          Center(
                            child: Text(
                              "Tu ubicación será enviada de forma automática,\n"
                              "no se registran datos personales.",

                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 11 * escala,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
      //  BOTTOM NAVIGATION
      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (widget.role) {
            case "usuario":
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
              break;

            case "administrador":
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
              break;
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

class _EstadosPainter extends CustomPainter {
  final int pendientes;
  final int revision;
  final int atendidos;

  const _EstadosPainter({
    required this.pendientes,
    required this.revision,
    required this.atendidos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = pendientes + revision + atendidos;
    final segmentos = [
      (pendientes, const Color(0xFFFFAA27)),
      (revision, const Color(0xFF8150A8)),
      (atendidos, const Color(0xFF159A70)),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.butt;
    if (total == 0) {
      paint.color = const Color(0xFFEFEAF3);
      canvas.drawArc(rect.deflate(9), -math.pi / 2, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (final (cantidad, color) in segmentos) {
      if (cantidad == 0) continue;
      final sweep = math.pi * 2 * cantidad / total;
      paint.color = color;
      canvas.drawArc(rect.deflate(9), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _EstadosPainter oldDelegate) =>
      oldDelegate.pendientes != pendientes ||
      oldDelegate.revision != revision ||
      oldDelegate.atendidos != atendidos;
}
