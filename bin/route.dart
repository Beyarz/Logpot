import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

class RouteHandler {
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

  Response _homeHandler(Request req) {
    return Response.ok(
      'People and bots have visited following pages:\n\n' +
          'Level,DateTime,Method,Path,User-agent\n' +
          File(logFileName).readAsStringSync()
    );
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
