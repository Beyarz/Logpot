import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

class RouteHandler {
  static const int _maxLinesToRead = 50;
  static const int _chunkSize = 16 * 1024; // 16KB per iter
  static const int _maxBytes = 64 * 1024; // cap total work 64KB
  static const Duration _cacheExpiry = Duration(seconds: 5);

  final String _robotsTxtFile = 'robots.txt';
  late final String _cacheRobotsTxt;
  late final Router _router;

  String? _cachedHomePage;
  DateTime? _cacheTime;
  bool _isRefreshingCache = false;

  Future<void> init() async {
    await _initRobotsCache();

    _router =
        Router()
          ..get('/', _homeHandler)
          ..get('/healthcheck', _healthcheckHandler)
          ..get(
            '/robots.txt',
            (Request req) => Response.ok(
              _cacheRobotsTxt,
              headers: {'Cache-Control': 'public, max-age=3600'},
            ),
          )
          ..get('/<catchAll|.*>', _catchAllHandler);
  }

  Router get router => _router;

  Future<Response> _homeHandler(Request req) async {
    if (_cachedHomePage != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
      return Response.ok(
        _cachedHomePage!,
        headers: {'Cache-Control': 'no-store'},
      );
    }

    // If another request is already refreshing
    // return stale cache or empty
    if (_isRefreshingCache) {
      return Response.ok(
        _cachedHomePage ?? 'Loading...',
        headers: {'Cache-Control': 'no-store'},
      );
    }

    _isRefreshingCache = true;

    try {
      final logTail = await _readLogTail();

      final buffer =
          StringBuffer()
            ..writeln('People and bots have visited following pages:\n')
            ..writeln('Level,DateTime,Method,Path');

      for (final line in logTail.split('\n')) {
        if (line.isEmpty) continue;

        final parts = line.split(',');

        if (parts.length >= 4) {
          String method = parts[2];
          String path = parts[3];

          try {
            method = Uri.decodeComponent(method);
          } catch (_) {
            // Keep encoded if decoding fails
          }

          try {
            path = Uri.decodeComponent(path);
          } catch (_) {
            // Keep encoded if decoding fails
          }

          final decoded = '${parts[0]},${parts[1]},$method,$path';
          buffer.writeln(decoded);
        } else {
          buffer.writeln(line);
        }
      }

      _cachedHomePage = buffer.toString();
      _cacheTime = DateTime.now();

      return Response.ok(
        _cachedHomePage!,
        headers: {'Cache-Control': 'no-store'},
      );
    } finally {
      _isRefreshingCache = false;
    }
  }

  Future<String> _readLogTail({int maxLines = _maxLinesToRead}) async {
    final file = File(logFileName);
    if (!await file.exists()) return '';

    final raf = await file.open();
    try {
      final List<int> buffer = [];
      int position = await raf.length();

      while (position > 0 && buffer.length < _maxBytes) {
        final readSize = position >= _chunkSize ? _chunkSize : position;
        position -= readSize;

        await raf.setPosition(position);
        buffer.insertAll(0, await raf.read(readSize));

        final lines = const LineSplitter().convert(utf8.decode(buffer));
        if (lines.length > maxLines) {
          return lines.sublist(lines.length - maxLines).join('\n');
        }
      }

      return const LineSplitter().convert(utf8.decode(buffer)).join('\n');
    } finally {
      await raf.close();
    }
  }

  Response _healthcheckHandler(Request req) {
    return Response.ok('Healthy');
  }

  Response _catchAllHandler(Request req) {
    return Response.ok('Thanks for visiting!\n\nNot much to see here.');
  }

  Future<void> _initRobotsCache() async {
    try {
      _cacheRobotsTxt = await File(_robotsTxtFile).readAsString();
    } catch (e) {
      throw FileSystemException(
        'File "robots.txt" not found. Have to be in same directory.',
      );
    }
  }
}
