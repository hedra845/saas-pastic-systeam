import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._internal();
  LocalDatabaseService._internal();

  File? _dbFile;
  bool _isInitialized = false;
  bool _isSaving = false;
  Map<String, dynamic>? _pendingSaveData;

  Future<File> get _file async {
    if (_dbFile != null) return _dbFile!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}${Platform.pathSeparator}plastic_factory_db.json';
      _dbFile = File(path);
    } catch (e) {
      // احتياطي في حال بيئات الاختبار
      _dbFile = File('plastic_factory_db.json');
    }
    return _dbFile!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final file = await _file;
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local database: $e');
    }
  }

  /// تحميل البيانات مع معالجة ذكية واستعادة تلقائية لأي تلف أو تكرار
  Future<Map<String, dynamic>?> loadData() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) return null;

        try {
          final data = jsonDecode(content) as Map<String, dynamic>;
          return data;
        } catch (formatErr) {
          debugPrint('Error loading local database: $formatErr');
          debugPrint('Attempting auto-recovery of database file...');

          final recovered = _tryRecoverJson(content);
          if (recovered != null) {
            debugPrint('Auto-recovery successful! Resaving clean database...');
            await saveData(recovered);
            return recovered;
          }

          // حفظ نسخة احتياطية من الملف التالف لعدم فقدان أي بيانات
          try {
            final backupFile = File('${file.path}.corrupt_${DateTime.now().millisecondsSinceEpoch}.bak');
            await file.copy(backupFile.path);
            debugPrint('Corrupted file backed up to: ${backupFile.path}');
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error loading local database: $e');
    }
    return null;
  }

  /// استعادة ومعالجة ملفات JSON التي تحتوي على أخطاء مثل تكرار الكائنات '}  {'
  Map<String, dynamic>? _tryRecoverJson(String content) {
    // 1. فحص إذا كان الملف يحتوي على كائنين مدمجين '}  {'
    final matches = RegExp(r'\}\s*\{').allMatches(content);
    if (matches.isNotEmpty) {
      final blocks = <String>[];
      int start = 0;
      for (final m in matches) {
        blocks.add(content.substring(start, m.start + 1).trim());
        start = m.end - 1; // البدء من القوس الثاني '{'
      }
      blocks.add(content.substring(start).trim());

      final validMaps = <Map<String, dynamic>>[];
      for (final b in blocks) {
        final parsed = _tryParseJsonObject(b);
        if (parsed != null) validMaps.add(parsed);
      }

      if (validMaps.isNotEmpty) {
        // دمج الكائنات بذكاء بحيث لا نفقد أي أصناف أو موردين
        final merged = <String, dynamic>{};
        for (final m in validMaps) {
          m.forEach((key, value) {
            if (!merged.containsKey(key)) {
              merged[key] = value;
            } else if (value is List && value.isNotEmpty) {
              final existingList = merged[key];
              if (existingList is List) {
                if (existingList.isEmpty) {
                  merged[key] = value;
                } else if (value.length > existingList.length) {
                  merged[key] = value;
                }
              }
            } else if (value != null && (merged[key] == null || (merged[key] is String && (merged[key] as String).isEmpty))) {
              merged[key] = value;
            }
          });
        }
        return merged;
      }
    }

    // 2. البحث عن أكبر نطاق كائن JSON متوازن { ... }
    final firstBrace = content.indexOf('{');
    final lastBrace = content.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      final candidate = content.substring(firstBrace, lastBrace + 1);
      final parsed = _tryParseJsonObject(candidate);
      if (parsed != null) return parsed;
    }

    return null;
  }

  Map<String, dynamic>? _tryParseJsonObject(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// حفظ البيانات بأمان تام (مع منع تعارض العمليات المتزامنة والنسخ الذري)
  Future<bool> saveData(Map<String, dynamic> data) async {
    _pendingSaveData = data;
    if (_isSaving) {
      return true; // العملية الحالية ستقوم بحفظ أحدث نسخة مسجلة في _pendingSaveData
    }
    _isSaving = true;

    try {
      while (_pendingSaveData != null) {
        final toSave = _pendingSaveData!;
        _pendingSaveData = null;

        final file = await _file;
        final jsonString = const JsonEncoder.withIndent('  ').convert(toSave);

        // كتابة الملف المؤقت أولاً
        final tempFile = File('${file.path}.tmp');
        await tempFile.writeAsString(jsonString, flush: true);

        try {
          // الاحتفاظ بنسخة احتياطية
          if (await file.exists()) {
            final bakFile = File('${file.path}.bak');
            try {
              if (await bakFile.exists()) await bakFile.delete();
              await file.copy(bakFile.path);
            } catch (_) {}
          }
          // نسخ الملف المؤقت فوق الملف الأساسي
          await tempFile.copy(file.path);
          await tempFile.delete();
        } catch (e) {
          // في حال كان الملف مغلقاً مؤقتاً بسبب برامج المزامنة (مثل OneDrive)
          await file.writeAsString(jsonString, flush: true);
          if (await tempFile.exists()) await tempFile.delete();
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error saving local database: $e');
      try {
        final file = await _file;
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        await file.writeAsString(jsonString, flush: true);
        return true;
      } catch (e2) {
        debugPrint('Fallback save also failed: $e2');
        return false;
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<String> getDatabasePath() async {
    final file = await _file;
    return file.path;
  }

  Future<int> getDatabaseSizeBytes() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  Future<bool> resetDatabase() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting local database: $e');
      return false;
    }
  }
}
