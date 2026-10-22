import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<List<dynamic>> _notificationsController =
      StreamController<List<dynamic>>.broadcast();

  Future<void>? _startFuture;
  List<dynamic> _notifications = [];
  Set<String> _notificationIds = {};
  bool _firstLoad = true;
  bool _isLoading = false;

  Stream<List<dynamic>> get notifications => _notificationsController.stream;
  List<dynamic> get currentNotifications => _notifications;
  Future<void> start() => _startFuture ??= _start();

  Future<void> _start() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setSource(AssetSource('sonido_notificacion.mp3'));
    } catch (error) {
      debugPrint("No se pudo preparar el sonido de notificación: $error");
    }

    await _loadNotifications();
    Timer.periodic(const Duration(seconds: 5), (_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final responses = await Future.wait([
        http.get(apiUri('/reporte')),
        http.get(apiUri('/emergencia')),
      ]);
      if (responses.any((response) => response.statusCode != 200)) {
        throw Exception('El servidor no pudo cargar las notificaciones.');
      }

      final reportes = _decodeList(
        responses[0].body,
        'Reporte',
      ).map((item) => {...item, 'categoria': 'Reporte'});
      final emergencias = _decodeList(
        responses[1].body,
        'Alerta SOS',
      ).map((item) => {...item, 'categoria': 'SOS'});
      final nuevasNotificaciones = [...reportes, ...emergencias];

      nuevasNotificaciones.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fecha']?.toString() ?? '');
        final fechaB = DateTime.tryParse(b['fecha']?.toString() ?? '');
        return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
      });

      final ids = nuevasNotificaciones
          .map(
            (item) =>
                '${item['categoria']}:${item['_id'] ?? item['fecha'] ?? ''}',
          )
          .toSet();

      if (!_firstLoad && ids.difference(_notificationIds).isNotEmpty) {
        await _playNotificationSound();
      }

      _notificationIds = ids;
      _firstLoad = false;
      _notifications = nuevasNotificaciones;
      _notificationsController.add(_notifications);
    } catch (error) {
      debugPrint("Error al cargar notificaciones: $error");
    } finally {
      _isLoading = false;
    }
  }

  List<Map<String, dynamic>> _decodeList(String body, String label) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw FormatException('La respuesta de $label no es válida.');
    }

    return decoded.map((item) {
      if (item is! Map) {
        throw FormatException('Un elemento de $label no es válido.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.resume();
    } catch (error) {
      debugPrint("No se pudo reproducir el sonido de notificación: $error");
    }
  }
}
