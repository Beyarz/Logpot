import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

class RouteHandler {
  static const int _maxLinesToRead = 50;
  static const int _chunkSize = 16 * 1024; // 16KB per iter
  static const int _maxBytes = 256 * 1024; // cap total work 256KB

  final String _robotsTxtFile = 'robots.txt';
  late final String _cacheRobotsTxt;
  late final Router _router;

  RouteHandler() {
    _initRobotsCache();

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
    final logTail = await _readLogTail();

    final buffer =
        StringBuffer()
          ..writeln('People and bots have visited following pages:\n')
          ..writeln('Level,DateTime,Method,Path\n')
          ..write(logTail);

    return Response.ok(
      buffer.toString(),
      headers: {'Cache-Control': 'no-store'},
    );
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
    return Response.ok('Nothing to see here');
  }

  void _initRobotsCache() {
    _cacheRobotsTxt = File(_robotsTxtFile).readAsStringSync();
  }
}
