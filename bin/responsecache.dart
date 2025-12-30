import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'config.dart';
import 'cacheentry.dart';

class ResponseCache {
  final String _cacheFilePath;
  final int _maxEntries;
  final Logger? _logger;
  final Map<String, CacheEntry> _cache = {};
  Timer? _saveTimer;
  bool _isSaving = false;

  ResponseCache({
    required String cacheFilePath,
    int maxEntries = maxCacheEntries,
    Logger? logger,
  }) : _cacheFilePath = cacheFilePath,
       _maxEntries = maxEntries,
       _logger = logger;

  Future<void> init() async {
    await _loadFromDisk();
  }

  String? get(String path) {
    final entry = _cache[path];

    if (entry != null) {
      entry.accessCount++;
      return entry.response;
    }

    return null;
  }

  Future<void> put(String path, String response) async {
    if (_cache.length >= _maxEntries && !_cache.containsKey(path)) {
      _evictLRU();
    }

    final entry = CacheEntry(
      path: path,
      response: response,
      timestamp: DateTime.now(),
      accessCount: 1,
    );

    _cache[path] = entry;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: cacheSaveDelaySec), _saveToDisk);
  }

  bool contains(String path) => _cache.containsKey(path);

  Future<void> close() async {
    _saveTimer?.cancel();
    await _saveToDisk();
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;

    String? lruKey;
    CacheEntry? lruEntry;

    for (final entry in _cache.entries) {
      if (lruEntry == null ||
          entry.value.accessCount < lruEntry.accessCount ||
          (entry.value.accessCount == lruEntry.accessCount &&
              entry.value.timestamp.isBefore(lruEntry.timestamp))) {
        lruKey = entry.key;
        lruEntry = entry.value;
      }
    }

    if (lruKey != null) {
      _cache.remove(lruKey);
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = File(_cacheFilePath);

      if (!await file.exists()) {
        return;
      }

      final content = await file.readAsString();

      final json = jsonDecode(content) as Map<String, dynamic>;
      final entries = json['entries'] as List<dynamic>? ?? [];

      for (final entryJson in entries) {
        try {
          final entry = CacheEntry.fromJson(entryJson as Map<String, dynamic>);
          _cache[entry.path] = entry;
        } catch (e) {
          _logger?.warning('Failed to parse cache entry: $e');
        }
      }
    } catch (e) {
      _logger?.warning('Failed to load cache from disk: $e');
    }
  }

  Future<void> _saveToDisk() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final file = File(_cacheFilePath);
      await file.parent.create(recursive: true);

      final json = {'entries': _cache.values.map((e) => e.toJson()).toList()};

      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      _logger?.warning('Failed to save cache to disk: $e');
    } finally {
      _isSaving = false;
    }
  }
}
