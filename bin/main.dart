import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_limiter/shelf_limiter.dart';
import 'package:logging/logging.dart';

import 'route.dart';
import 'log.dart';
import 'persistence.dart';
import 'context.dart';
import 'config.dart';

Future<void> main() async {
  final Log loggerConfig = Log("Global");
  final Logger log = loggerConfig.logger;

  final Persistence persistence = await Persistence.createFile(
    logFileName,
    maxSizeBytes: maxLogFileSize,
    logger: log,
  );

  final Persistence errorPersistence = await Persistence.createFile(
    errorLogFileName,
    maxSizeBytes: maxLogFileSize,
    logger: log,
  );

  loggerConfig.addOutput(persistence.log);
  loggerConfig.addErrorOutput(errorPersistence.log);

  final routeHandler = RouteHandler(logger: log);
  await routeHandler.init();

  final rateLimiter = shelfLimiter(
    RateLimiterOptions(maxRequests: 25, windowSize: const Duration(minutes: 1)),
  );

  final Handler handler = Pipeline()
      .addMiddleware(_requestBodySizeLimitMiddleware(maxRequestBodySize))
      .addMiddleware(rateLimiter)
      .addMiddleware(
        (innerHandler) => (request) {
          if (request.requestedUri.path != '/') {
            final method = Uri.encodeComponent(request.method);
            final path = Uri.encodeComponent(request.requestedUri.path);

            if (request.requestedUri.path == '/private') {
              log.warning('$method,$path');
            } else {
              log.info('$method,$path');
            }
          }

          return innerHandler(request);
        },
      )
      .addMiddleware(
        (innerHandler) => (request) async {
          final response = await innerHandler(request);
          return response.change(
            headers: {
              'Server': 'Apache/2.4.41 (Ubuntu)',
              'X-Powered-By': 'PHP/7.4.16',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'ETag': '"${DateTime.now().millisecondsSinceEpoch}"',
              'Last-Modified': HttpDate.format(DateTime.now()),
              'X-Frame-Options': 'DENY',
              'X-Content-Type-Options': 'nosniff',
              'Strict-Transport-Security':
                  'max-age=31536000; includeSubDomains',

              // Prevent someone from bypass Request-body limit
              // and streams gigabytes to exhaust
              'Connection': 'close',
            },
          );
        },
      )
      .addHandler(routeHandler.router.call);

  final SecurityContext securityContext = createSecurityContext(logger: log);
  final int port = int.parse(Platform.environment['PORT'] ?? '8081');

  final HttpServer serverv4 =
      await HttpServer.bindSecure(
          InternetAddress.anyIPv4,
          port,
          securityContext,
        )
        ..autoCompress = true
        ..idleTimeout = const Duration(seconds: 10);

  final HttpServer serverv6 =
      await HttpServer.bindSecure(
          InternetAddress.anyIPv6,
          port,
          securityContext,
        )
        ..autoCompress = true
        ..idleTimeout = const Duration(seconds: 10);

  serveRequests(serverv4, handler);
  serveRequests(serverv6, handler);
  registerSignalHandler(
    () => shutdown(
      log,
      serverv4,
      serverv6,
      loggerConfig,
      persistence,
      errorPersistence,
    ),
  );

  print("""
  \nServer listening on:
  https://localhost:${serverv4.port}
  https://${serverv4.address.address}:${serverv4.port}
  https://${serverv6.address.address}:${serverv6.port}
""");

  log.info("Testing");
  log.severe("Testing");
}

Middleware _requestBodySizeLimitMiddleware(int maxBytes) {
  return (innerHandler) => (request) async {
    if (request.contentLength != null && request.contentLength! > maxBytes) {
      return Response(
        payloadTooLargeError,
        body: 'Request body too large',
        headers: {'Content-Type': 'text/plain'},
      );
    }

    return innerHandler(request);
  };
}

void registerSignalHandler(Future<void> Function() onSignal) {
  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    signal.watch().listen((_) async {
      await onSignal();
      exit(exitSuccess);
    });
  }
}

Future<void> shutdown(
  Logger log,
  HttpServer serverv4,
  HttpServer serverv6,
  Log loggerConfig,
  Persistence persistence,
  Persistence errorPersistence,
) async {
  print('Shutting down...');
  await serverv4.close(force: true);
  await serverv6.close(force: true);
  await loggerConfig.dispose();
  await persistence.close();
  await errorPersistence.close();
}
