import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'main.dart';

const String robotsTxtFile = 'robots.txt';
late final String cacheRobotsTxt;

final router =
    Router()
      ..get('/', _homeHandler)
      ..get('/robots.txt', (Request req) => Response.ok(cacheRobotsTxt))
      ..get('/<catchAll|.*>', _catchAllHandler);

Response _homeHandler(Request req) {
  return Response.ok(File(logFileName).readAsStringSync());
}

Response _catchAllHandler(Request req) {
  return Response.ok('You are on page: ${req.requestedUri.path}');
}

void initRobotsCache() {
  cacheRobotsTxt = File(robotsTxtFile).readAsStringSync();
}
