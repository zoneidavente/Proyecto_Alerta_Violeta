import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdministrarReportesPage extends StatefulWidget {
  final String alias;
  final String role;

  const AdministrarReportesPage({
    super.key,
    required this.alias,
    required this.role,
  });

  @override
  State<AdministrarReportesPage> createState() =>
      _AdministrarReportesPageState();
}

class _AdministrarReportesPageState extends State<AdministrarReportesPage> {
  static const _api = 'http://192.168.20.32:3000';
  static const _pageSize = 10;
  static const _purple = Color(0xFF54216F);
  static const _border = Color(0xFFE9E3EE);

  List<dynamic> reportes = [];
  List<dynamic> alertas = [];
  bool cargando = true;
  String? error;
  int paginaActual = 0;
  String filtroEstado = 'Todos';

  static const _filtrosEstado = [
    'Todos',
    'Pendientes',
    'En revisión',
    'Atendidos',
  ];

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

  Future<void> cargarReportes() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      final respuestas = await Future.wait([
        http.get(Uri.parse('$_api/reporte')),
        http.get(Uri.parse('$_api/emergencia')),
      ]);
      if (respuestas.any((respuesta) => respuesta.statusCode != 200)) {
        throw Exception('No se pudieron recuperar los reportes y alertas.');
      }
      final dataReportes = jsonDecode(respuestas[0].body);
      final dataAlertas = jsonDecode(respuestas[1].body);
      if (dataReportes is! List || dataAlertas is! List) {
        throw const FormatException('La respuesta de reportes no es válida.');
      }
      if (!mounted) return;
      setState(() {
        reportes = dataReportes;
        alertas = dataAlertas;
        paginaActual = 0;
        cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'No se pudieron cargar los reportes. Intenta nuevamente.';
        cargando = false;
      });
    }
  }

  String _estado(dynamic reporte) =>
      reporte['estado']?.toString() ?? 'Pendiente';

  List<Map<String, dynamic>> get _elementos {
    final elementos = <Map<String, dynamic>>[];
    for (var i = 0; i < reportes.length; i++) {
      elementos.add({'esAlerta': false, 'numero': i + 1, 'dato': reportes[i]});
    }
    for (var i = 0; i < alertas.length; i++) {
      elementos.add({'esAlerta': true, 'numero': i + 1, 'dato': alertas[i]});
    }
    elementos.sort((a, b) {
      final fechaA = DateTime.tryParse(a['dato']['fecha']?.toString() ?? '');
      final fechaB = DateTime.tryParse(b['dato']['fecha']?.toString() ?? '');
      return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
    });
    var numeroReporte = 0;
    var numeroAlerta = 0;
    for (final elemento in elementos) {
      if (elemento['esAlerta'] as bool) {
        elemento['numero'] = ++numeroAlerta;
      } else {
        elemento['numero'] = ++numeroReporte;
      }
    }
    return elementos;
  }

  String _categoriaEstado(dynamic valor) {
    switch ((valor?.toString() ?? 'Pendiente').toLowerCase().trim()) {
      case 'en revisión':
      case 'en_revision':
        return 'En revisión';
      case 'atendido':
      case 'cerrado':
        return 'Atendidos';
      default:
        return 'Pendientes';
    }
  }

  List<Map<String, dynamic>> get _elementosFiltrados {
    final elementos = _elementos;
    if (filtroEstado == 'Todos') return elementos;
    return elementos
        .where(
          (elemento) =>
              _categoriaEstado(_estado(elemento['dato'])) == filtroEstado,
        )
        .toList();
  }

  int _contarFiltro(String filtro) {
    if (filtro == 'Todos') return _elementos.length;
    return _elementos
        .where(
          (elemento) => _categoriaEstado(_estado(elemento['dato'])) == filtro,
        )
        .length;
  }

  String _tituloElemento(Map<String, dynamic> elemento) {
    final esAlerta = elemento['esAlerta'] as bool;
    final tipo = esAlerta ? 'Alerta SOS' : 'Reporte';
    final numero = (elemento['numero'] as int).toString().padLeft(3, '0');
    return '$tipo #$numero';
  }

  String _subtituloElemento(Map<String, dynamic> elemento) {
    if (elemento['esAlerta'] as bool) return 'Alerta SOS';
    return elemento['dato']['tipo_acoso']?.toString() ?? 'Reporte de acoso';
  }

  Color _colorTipo(Map<String, dynamic> elemento) =>
      elemento['esAlerta'] as bool
      ? const Color(0xFFE65362)
      : const Color(0xFF8150A8);

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'en revisión':
      case 'en_revision':
        return const Color(0xFF8150A8);
      case 'atendido':
        return const Color(0xFF21865B);
      case 'cerrado':
        return const Color(0xFF74677D);
      default:
        return const Color(0xFFE09514);
    }
  }

  String _fecha(dynamic valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '')?.toLocal();
    if (fecha == null) return 'Fecha no disponible';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}\n$hora:$minuto';
  }

  String _ubicacion(dynamic reporte) {
    final direccion = reporte['direccion']?.toString().trim();
    if (direccion != null && direccion.isNotEmpty) return direccion;
    final latitud = reporte['latitud'];
    final longitud = reporte['longitud'];
    if (latitud != null && longitud != null) return '$latitud, $longitud';
    return 'Ubicación no disponible';
  }

  Future<void> _actualizarEstado(
    Map<String, dynamic> elemento,
    String nuevoEstado,
  ) async {
    final reporte = elemento['dato'];
    final esAlerta = elemento['esAlerta'] as bool;
    final id = reporte['_id']?.toString();
    if (id == null || id.isEmpty) {
      _mostrarMensaje('No se encontró el identificador del reporte.');
      return;
    }

    try {
      final respuesta = await http.put(
        Uri.parse('$_api/${esAlerta ? 'emergencia' : 'reporte'}/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (respuesta.statusCode != 200) {
        throw Exception('El servidor respondió ${respuesta.statusCode}.');
      }
      if (!mounted) return;
      setState(() {
        final lista = esAlerta ? alertas : reportes;
        final indice = lista.indexWhere(
          (elemento) => elemento['_id']?.toString() == id,
        );
        if (indice != -1) {
          lista[indice] = {...lista[indice], 'estado': nuevoEstado};
        }
      });
      _mostrarMensaje('Estado actualizado correctamente.');
    } catch (_) {
      _mostrarMensaje('No se pudo actualizar el estado del reporte.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _verDetalle(Map<String, dynamic> elemento) {
    final reporte = elemento['dato'];
    final esAlerta = elemento['esAlerta'] as bool;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_tituloElemento(elemento)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detalle(
                  'Alias',
                  reporte['alias']?.toString() ?? 'No disponible',
                ),
                _detalle(
                  'Tipo de acoso',
                  esAlerta
                      ? 'alerta SOS'
                      : reporte['tipo_acoso']?.toString() ?? 'No especificado',
                ),
                _detalle(
                  'Fecha',
                  _fecha(reporte['fecha']).replaceAll('\n', ' · '),
                ),
                _detalle('Ubicación', _ubicacion(reporte)),
                _detalle('Estado', _estado(reporte)),
                _detalle(
                  'Descripción',
                  esAlerta
                      ? 'Alerta de emergencia enviada por la persona usuaria.'
                      : reporte['descripcion']?.toString() ?? 'Sin descripción',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _detalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF816A91),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            valor,
            style: const TextStyle(color: Color(0xFF39274A), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _estadoDropdown(Map<String, dynamic> elemento) {
    const estados = ['Pendiente', 'En revisión', 'Atendido', 'Cerrado'];
    final estado = _estado(elemento['dato']);
    final valor = estados.contains(estado) ? estado : 'Pendiente';
    final color = _colorEstado(valor);

    return Container(
      padding: const EdgeInsets.only(left: 9, right: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, color: color, size: 18),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          items: estados
              .map(
                (opcion) =>
                    DropdownMenuItem(value: opcion, child: Text(opcion)),
              )
              .toList(),
          onChanged: (nuevoEstado) {
            if (nuevoEstado != null && nuevoEstado != valor) {
              _actualizarEstado(elemento, nuevoEstado);
            }
          },
        ),
      ),
    );
  }

  Widget _tablaReportes() {
    final elementos = _elementosFiltrados;
    final inicio = paginaActual * _pageSize;
    final fin = (inicio + _pageSize).clamp(0, elementos.length);
    final visibles = elementos.sublist(inicio, fin);

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF7F4FA),
                ),
                headingTextStyle: const TextStyle(
                  color: Color(0xFF6B5B79),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF39274A),
                  fontSize: 11,
                ),
                horizontalMargin: 12,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('REPORTE')),
                  DataColumn(label: Text('ALIAS')),
                  DataColumn(label: Text('UBICACIÓN')),
                  DataColumn(label: Text('FECHA')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: [for (final elemento in visibles) _filaReporte(elemento)],
              ),
            ),
          ),
          const Divider(height: 1, color: _border),
          _paginacion(inicio, fin),
        ],
      ),
    );
  }

  Widget _filtros() {
    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filtro in _filtrosEstado)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filtroEstado(filtro),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filtroEstado(String filtro) {
    final seleccionado = filtroEstado == filtro;
    final cantidad = _contarFiltro(filtro);

    return Material(
      color: seleccionado ? _purple : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() {
          filtroEstado = filtro;
          paginaActual = 0;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filtro,
                style: TextStyle(
                  color: seleccionado ? Colors.white : const Color(0xFF594C64),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF0EAF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    color: seleccionado ? Colors.white : _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _filaReporte(Map<String, dynamic> elemento) {
    final reporte = elemento['dato'];
    final colorTipo = _colorTipo(elemento);
    final ubicacion = _ubicacion(reporte);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 125,
            child: Row(
              children: [
                Icon(
                  (elemento['esAlerta'] as bool)
                      ? Icons.warning_rounded
                      : Icons.description_outlined,
                  color: colorTipo,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tituloElemento(elemento),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _subtituloElemento(elemento),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF816A91),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 85,
            child: Text(
              reporte['alias']?.toString() ?? 'No disponible',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              ubicacion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(_fecha(reporte['fecha']))),
        DataCell(_estadoDropdown(elemento)),
        DataCell(
          OutlinedButton(
            onPressed: () => _verDetalle(elemento),
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              side: const BorderSide(color: Color(0xFFD9CBE3)),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Ver detalle'),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaElemento(Map<String, dynamic> elemento) {
    final reporte = elemento['dato'];
    final colorTipo = _colorTipo(elemento);
    final esAlerta = elemento['esAlerta'] as bool;
    final descripcion = reporte['descripcion']?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esAlerta ? Icons.warning_rounded : Icons.description_outlined,
                  color: colorTipo,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tituloElemento(elemento),
                        style: const TextStyle(
                          color: Color(0xFF39274A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _subtituloElemento(elemento),
                        style: TextStyle(color: colorTipo, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _estadoDropdown(elemento),
              ],
            ),
            const SizedBox(height: 12),
            _detalle('Alias', reporte['alias']?.toString() ?? 'No disponible'),
            _detalle('Ubicación', _ubicacion(reporte)),
            _detalle('Fecha', _fecha(reporte['fecha']).replaceAll('\n', ' · ')),
            if (!esAlerta && descripcion != null && descripcion.isNotEmpty)
              _detalle('Descripción', descripcion),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _verDetalle(elemento),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFD9CBE3)),
                ),
                child: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginacion(int inicio, int fin) {
    final total = _elementosFiltrados.length;
    final totalPaginas = (total / _pageSize).ceil();
    final primerRegistro = total == 0 ? 0 : inicio + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$primerRegistro–$fin de $total',
            style: const TextStyle(color: Color(0xFF816A91), fontSize: 11),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Página anterior',
            onPressed: paginaActual > 0
                ? () => setState(() => paginaActual--)
                : null,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '${paginaActual + 1} / ${totalPaginas == 0 ? 1 : totalPaginas}',
            style: const TextStyle(
              color: _purple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: paginaActual + 1 < totalPaginas
                ? () => setState(() => paginaActual++)
                : null,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F9),
        foregroundColor: _purple,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: cargarReportes,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _elementos.isEmpty
          ? const Center(
              child: Text('No hay reportes ni alertas SOS registrados.'),
            )
          : RefreshIndicator(
              onRefresh: cargarReportes,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inicio = paginaActual * _pageSize;
                  final elementos = _elementosFiltrados;
                  final fin = (inicio + _pageSize).clamp(0, elementos.length);
                  final visibles = elementos.sublist(inicio, fin);
                  final esPantallaCompacta = constraints.maxWidth < 760;

                  return ListView(
                    padding: EdgeInsets.all(esPantallaCompacta ? 12 : 16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'Gestionar reportes',
                          style: TextStyle(
                            color: Color(0xFF321443),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _filtros(),
                      if (esPantallaCompacta)
                        if (visibles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: Text('No hay elementos en este estado.'),
                            ),
                          )
                        else
                          ...visibles.map(_tarjetaElemento)
                      else if (visibles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text('No hay elementos en este estado.'),
                          ),
                        )
                      else
                        Card(
                          clipBehavior: Clip.antiAlias,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _border),
                          ),
                          child: _tablaReportes(),
                        ),
                      if (esPantallaCompacta)
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _border),
                          ),
                          child: _paginacion(inicio, fin),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
