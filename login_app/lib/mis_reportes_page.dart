import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

import 'api_config.dart';
import 'app_session.dart';

class MisReportesPage extends StatefulWidget {
  final String alias;

  const MisReportesPage({super.key, required this.alias});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage> {
  List<dynamic> reportes = [];
  List<dynamic> alertas = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _cargarRegistros();
  }

  Future<void> _cargarRegistros() async {
    try {
      final response = await http.get(
        apiUri('/mis-registros'),
        headers: AppSession.authHeaders(),
      );
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}.');
      }
      final data = jsonDecode(response.body);
      if (data is! Map ||
          data['reportes'] is! List ||
          data['alertas'] is! List) {
        throw const FormatException('La respuesta de registros no es válida.');
      }
      if (!mounted) return;
      setState(() {
        reportes = List<dynamic>.from(data['reportes']);
        alertas = List<dynamic>.from(data['alertas']);
        cargando = false;
        error = null;
      });
    } catch (exception) {
      debugPrint('Error al cargar registros propios: $exception');
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = 'No se pudieron cargar tus registros.';
      });
    }
  }

  List<Map<String, dynamic>> get _registros {
    final elementos = <Map<String, dynamic>>[
      ...reportes.map((reporte) => {'esAlerta': false, 'dato': reporte}),
      ...alertas.map((alerta) => {'esAlerta': true, 'dato': alerta}),
    ];
    elementos.sort((a, b) {
      final fechaA = DateTime.tryParse(a['dato']['fecha']?.toString() ?? '');
      final fechaB = DateTime.tryParse(b['dato']['fecha']?.toString() ?? '');
      return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
    });
    return elementos;
  }

  Future<void> _editarReporte(Map<String, dynamic> reporte) async {
    final tipoController = TextEditingController(
      text: reporte['tipo_acoso']?.toString() ?? '',
    );
    final descripcionController = TextEditingController(
      text: reporte['descripcion']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final cambios = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar reporte detallado'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tipoController,
                  decoration: const InputDecoration(labelText: 'Tipo de acoso'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Completa el tipo de acoso.'
                      : null,
                ),
                TextFormField(
                  controller: descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Completa la descripción.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, {
                'tipo_acoso': tipoController.text.trim(),
                'descripcion': descripcionController.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    tipoController.dispose();
    descripcionController.dispose();
    if (cambios == null) return;

    final id = reporte['_id']?.toString();
    if (id == null || id.isEmpty) {
      _mostrarMensaje('No se encontró el identificador del reporte.');
      return;
    }

    try {
      final response = await http.put(
        apiUri('/reporte/$id'),
        headers: AppSession.authHeaders(json: true),
        body: jsonEncode(cambios),
      );
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}.');
      }
      await _cargarRegistros();
      _mostrarMensaje('Reporte actualizado.');
    } catch (exception) {
      debugPrint('Error al actualizar reporte propio: $exception');
      _mostrarMensaje('No se pudo actualizar el reporte.');
    }
  }

  Future<void> _eliminarRegistro(Map<String, dynamic> elemento) async {
    final esAlerta = elemento['esAlerta'] as bool;
    final registro = elemento['dato'] as Map<String, dynamic>;
    final id = registro['_id']?.toString();
    if (id == null || id.isEmpty) {
      _mostrarMensaje('No se encontró el identificador del registro.');
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(esAlerta ? 'Eliminar alerta SOS' : 'Eliminar reporte'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      final response = await http.delete(
        apiUri('/${esAlerta ? 'emergencia' : 'reporte'}/$id'),
        headers: AppSession.authHeaders(),
      );
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}.');
      }
      await _cargarRegistros();
      _mostrarMensaje(
        esAlerta ? 'Alerta SOS eliminada.' : 'Reporte eliminado.',
      );
    } catch (exception) {
      debugPrint('Error al eliminar registro propio: $exception');
      _mostrarMensaje('No se pudo eliminar el registro.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _construirRegistros() {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cargarRegistros,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final elementos = _registros;
    if (elementos.isEmpty) {
      return const Center(
        child: Text('Aún no tienes reportes ni alertas SOS.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarRegistros,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: elementos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final elemento = elementos[index];
          final esAlerta = elemento['esAlerta'] as bool;
          final registro = elemento['dato'] as Map<String, dynamic>;
          final color = esAlerta ? Colors.red.shade700 : Colors.deepPurple;
          final fecha = DateTime.tryParse(registro['fecha']?.toString() ?? '');
          final fechaTexto = fecha == null
              ? 'Fecha no disponible'
              : timeago.format(fecha, locale: 'es');
          return Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        esAlerta ? Icons.sos : Icons.description_outlined,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          esAlerta
                              ? 'Alerta SOS · $fechaTexto'
                              : '${registro['tipo_acoso'] ?? 'Reporte'} · $fechaTexto',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (!esAlerta) ...[
                    const SizedBox(height: 6),
                    Text(registro['descripcion']?.toString() ?? ''),
                  ],
                  if (registro['direccion']?.toString().trim().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 6),
                    Text(
                      registro['direccion'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 4,
                      children: [
                        if (!esAlerta)
                          TextButton.icon(
                            onPressed: () => _editarReporte(registro),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar'),
                          ),
                        TextButton.icon(
                          onPressed: () => _eliminarRegistro(elemento),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Eliminar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDF5),
      appBar: AppBar(
        title: const Text('Mis reportes'),
        backgroundColor: const Color(0xFFAB8FB8),
        foregroundColor: const Color(0xFF3C154E),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registros de ${widget.alias}',
                style: const TextStyle(
                  color: Color(0xFF321443),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _construirRegistros()),
            ],
          ),
        ),
      ),
    );
  }
}
