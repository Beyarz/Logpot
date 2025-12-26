import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

class RouteHandler {
  static const int _logTailBytes = 64 * 1024 * 1024; // 64MB

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

  Future<String> _readLogTail({int maxLines = 50}) async {
    final file = File(logFileName);
    if (!await file.exists()) {
      return '';
    }

    final length = await file.length();
    final start = length > _logTailBytes ? length - _logTailBytes : 0;
    final rawTail = await file.openRead(start).transform(utf8.decoder).join();

    final lines = const LineSplitter().convert(rawTail);
    if (lines.length <= maxLines) {
      return lines.join('\n');
    }

    return lines.sublist(lines.length - maxLines).join('\n');
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
