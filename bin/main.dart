import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:logging/logging.dart';
import 'routes.dart';
import 'logger.dart';

Future<void> main() async {
  Logger log = Log("Global").getInstance;

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final ipv4 = InternetAddress.anyIPv4;
  final ipv6 = InternetAddress.anyIPv6;

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final serverv4 = await serve(handler, ipv4, port);
  final serverv6 = await serve(handler, ipv6, port);

  log.info("""
  \nServer listening on:
  http://${serverv4.address.address}:${serverv4.port}
  http://${serverv6.address.address}:${serverv6.port}
""");
}
