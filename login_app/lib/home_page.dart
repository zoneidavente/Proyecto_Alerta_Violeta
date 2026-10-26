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
import 'app_session.dart';
import 'mis_reportes_page.dart';
import 'login_page.dart';

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
        headers: AppSession.authHeaders(json: true),
        body: jsonEncode({
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

  void _abrirPerfil() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8FC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF64318B), Color(0xFF8C56BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 42,
                        color: Color(0xFF704092),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.alias,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'Tu perfil',
                      style: TextStyle(
                        color: Color(0xFFE9DDF3),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF60317D),
                ),
                title: const Text(
                  'Mis reportes',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MisReportesPage(alias: widget.alias),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB3261E)),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFB3261E),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  AppNotificationService.instance.stop();
                  AppSession.clear();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (_) => false,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirInicioUsuario() {
    const lavanda = Color(0xFFF3EDF5);
    const moradoSuave = Color(0xFFAB8FB8);

    return Stack(
      children: [
        Container(color: lavanda),
        Positioned(
          top: -290,
          left: -130,
          child: Transform.translate(
            offset: const Offset(-90, -90),
            child: Container(
              width: 800,
              height: 420,
              decoration: const BoxDecoration(
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
            offset: const Offset(-98, -98),
            child: Container(
              width: 400,
              height: 390,
              decoration: BoxDecoration(
                color: moradoSuave.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(color: moradoSuave.withValues(alpha: 0.4)),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final escala = (constraints.maxHeight / 780).clamp(0.82, 1.0);
              final altoDisponible = constraints.maxHeight - 80 - 48;
              final altoTarjeta = (altoDisponible * 0.9).clamp(400.0, 450.0);

              return Column(
                children: [
                  _encabezadoInicio(escala),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          sliver: SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: _tarjetaInicio(escala, altoTarjeta),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'Tu ubicación será enviada de forma automática,\n'
                      'no se registran datos personales.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6F5B7A),
                        fontSize: 10.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _encabezadoInicio(double escala) {
    const morado = Color(0xFF3C154E);
    const violeta = Color(0xFF9B43C0);
    final logo = 58 * escala;
    final perfil = 44 * escala;

    return SizedBox(
      height: 80,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: logo,
              height: logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.shield_outlined, size: logo * 0.8, color: morado),
            ),
            SizedBox(width: 10 * escala),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALERTA',
                  style: TextStyle(
                    color: morado,
                    fontSize: 21 * escala,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    height: 0.98,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  'VIOLETA',
                  style: TextStyle(
                    color: violeta,
                    fontSize: 21 * escala,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    height: 0.98,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _abrirPerfil,
                borderRadius: BorderRadius.circular(40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: perfil + 4,
                        height: perfil + 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: violeta.withValues(alpha: 0.75),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: morado,
                          size: perfil * 0.56,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mi perfil',
                        style: TextStyle(
                          color: morado,
                          fontSize: 10.5 * escala,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaInicio(double escala, double altoTotal) {
    const morado = Color(0xFF4E1A66);
    const violeta = Color(0xFF9B43C0);
    const rojo = Color(0xFFF21F3D);
    final anchoSOS = 160 * escala;
    final margenTarjeta = 20 + anchoSOS * 0.62;
    final espacioSuperiorTarjeta = anchoSOS - (margenTarjeta - 20) + 26;
    final altoTarjeta = altoTotal - margenTarjeta;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: altoTarjeta,
            margin: EdgeInsets.only(top: margenTarjeta),
            padding: EdgeInsets.fromLTRB(22, espacioSuperiorTarjeta, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x123C154E)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F3C154E),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x0DFFFFFF),
                  blurRadius: 2,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Estamos contigo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: morado,
                    fontSize: 17 * escala,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 6 * escala),
                Text(
                  'Tu alerta se envía de inmediato.\n'
                  'Si no es una emergencia, puedes reportar lo ocurrido con más detalle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF7A6A84),
                    fontSize: 11 * escala,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16 * escala),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEADCF5)),
                  ),
                ),
                const Spacer(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: Material(
                        color: const Color(0xFFEADCF5),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportePage(
                                alias: widget.alias,
                                role: widget.role,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: morado,
                                size: 18 * escala,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Crear reporte detallado',
                                style: TextStyle(
                                  color: morado,
                                  fontSize: 12.5 * escala,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4 * escala),
              ],
            ),
          ),
          Positioned(top: 0, child: _botonSOS(anchoSOS, rojo: rojo)),
        ],
      ),
    );
  }

  Widget _botonSOS(double tamano, {required Color rojo}) {
    final halo = tamano + 36;

    return SizedBox(
      width: halo,
      height: halo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: halo,
            height: halo,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  rojo.withValues(alpha: 0.38),
                  rojo.withValues(alpha: 0.16),
                  rojo.withValues(alpha: 0),
                ],
                stops: const [0.42, 0.68, 1],
              ),
            ),
          ),
          Container(
            width: tamano,
            height: tamano,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF5064), Color(0xFFE00D2D)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: rojo.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: rojo.withValues(alpha: 0.22),
                  blurRadius: 58,
                  spreadRadius: 16,
                ),
                const BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enviarAlertaSOS,
                customBorder: const CircleBorder(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31 * (tamano / 160),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Alerta inmediata',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5 * (tamano / 160),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fondo = Color(0xFFF3EDF5);
    Color moradoSuave = Color(0xFFAB8FB8);
    Color moradoIconos = Color.fromARGB(255, 60, 21, 78);

    return Scaffold(
      backgroundColor: fondo,

      body: widget.role == "administrador"
          ? _construirPanelAdmin()
          : _construirInicioUsuario(),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MapaPage(alias: widget.alias, role: widget.role),
                    ),
                  );
                  break;
                case 3:
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
                  icon: Icon(Icons.location_on),
                  label: "Mapa",
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
