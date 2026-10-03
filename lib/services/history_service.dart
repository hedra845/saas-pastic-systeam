// lib/services/history_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class HistoryEvent {
  final String id;
  final DateTime timestamp;
  final String type; // e.g. 'product_add', 'login', 'db_clear' …
  final String title;
  final String? details;
  final String user;

  const HistoryEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    this.details,
    this.user = 'مدير النظام',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'title': title,
        'details': details,
        'user': user,
      };

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => HistoryEvent(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: json['type'] as String,
        title: json['title'] as String,
        details: json['details'] as String?,
        user: json['user'] as String? ?? 'مدير النظام',
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class HistoryService {
  HistoryService._privateConstructor();
  static final HistoryService instance = HistoryService._privateConstructor();

  static const String _fileName = 'history_log.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Loads the full list of events from disk (newest first).
  Future<List<HistoryEvent>> loadHistory() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> raw = jsonDecode(content) as List<dynamic>;
      return raw
          .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('[HistoryService] loadHistory error: $e');
      return [];
    }
  }

  /// Appends a new event and immediately persists the log to disk.
  Future<void> logEvent({
    required String type,
    required String title,
    String? details,
    String? entityId,
    String user = 'مدير النظام',
  }) async {
    try {
      final existing = await loadHistory();
      final event = HistoryEvent(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}${entityId != null ? '-$entityId' : ''}',
        timestamp: DateTime.now(),
        type: type,
        title: title,
        details: details,
        user: user,
      );
      // Insert newest first
      existing.insert(0, event);
      await _save(existing);
    } catch (e) {
      debugPrint('[HistoryService] logEvent error: $e');
    }
  }

  /// Clears ALL history events. Should only be called after password verification.
  Future<void> clearHistory() async {
    try {
      await _save([]);
    } catch (e) {
      debugPrint('[HistoryService] clearHistory error: $e');
    }
  }

  // Internal helper: serialise the list to disk.
  Future<void> _save(List<HistoryEvent> events) async {
    final file = await _getFile();
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded, flush: true);
  }
}
