import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

class RouteHandler {
  final String robotsTxtFile = 'robots.txt';
  late final String _cacheRobotsTxt;
  late final Router _router;

  RouteHandler() {
    _initRobotsCache();

    _router =
        Router()
          ..get('/', _homeHandler)
          ..get('/robots.txt', (Request req) => Response.ok(_cacheRobotsTxt))
          ..get('/<catchAll|.*>', _catchAllHandler);
  }

  Router get router => _router;

  Response _homeHandler(Request req) {
    return Response.ok(File(logFileName).readAsStringSync());
  }

  Response _catchAllHandler(Request req) {
    return Response.ok('You are on page: ${req.requestedUri.path}');
  }

  void _initRobotsCache() {
    _cacheRobotsTxt = File(robotsTxtFile).readAsStringSync();
  }
}
