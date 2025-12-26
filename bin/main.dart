import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_limiter/shelf_limiter.dart';
import 'package:logging/logging.dart';

import 'route.dart';
import 'log.dart';
import 'persistence.dart';

const logFileName = 'request-logs.txt';
const errorLogFileName = 'error-logs.txt';
const exitSuccess = 0;
const int payloadTooLargeError = 413;
const int maxRequestBodySize = 10 * 1024 * 1024; // 10MB

Future<void> main() async {
  final Log loggerConfig = Log("Global");
  final Logger log = loggerConfig.logger;

  final Persistence persistence = await Persistence.createFile(logFileName);
  final Persistence errorPersistence = await Persistence.createFile(
    errorLogFileName,
  );

  loggerConfig.addOutput(persistence.log);
  loggerConfig.addErrorOutput(errorPersistence.log);

  final routeHandler = RouteHandler();
  await routeHandler.init();

  final rateLimiter = shelfLimiterByEndpoint(
    endpointLimits: {
      '/': RateLimiterOptions(
        maxRequests: 30,
        windowSize: const Duration(minutes: 1),
      ),
      '/healthcheck': RateLimiterOptions(
        maxRequests: 60,
        windowSize: const Duration(minutes: 1),
      ),
    },
    defaultOptions: RateLimiterOptions(
      maxRequests: 100,
      windowSize: const Duration(minutes: 1),
    ),
  );

  final Handler handler = Pipeline()
      .addMiddleware(_requestBodySizeLimitMiddleware(maxRequestBodySize))
      .addMiddleware(rateLimiter)
      .addMiddleware(
        (innerHandler) => (request) {
          if (request.requestedUri.path != '/') {
            final method = Uri.encodeComponent(request.method);
            final path = Uri.encodeComponent(request.requestedUri.path);
            log.info('$method,$path');
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
            },
          );
        },
      )
      .addHandler(routeHandler.router.call);

  final int port = int.parse(Platform.environment['PORT'] ?? '8081');

  final HttpServer serverv4 = await serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    )
    ..autoCompress = true;

  final HttpServer serverv6 = await serve(
      handler,
      InternetAddress.anyIPv6,
      port,
    )
    ..autoCompress = true;

  registerSignalHandler(() async {
    print('Shutting down...');
    await serverv4.close(force: true);
    await serverv6.close(force: true);
    await loggerConfig.dispose();
    await persistence.close();
    await errorPersistence.close();
  });

  print("""
  \nServer listening on:
  http://${serverv4.address.address}:${serverv4.port}
  http://${serverv6.address.address}:${serverv6.port}
""");
}

Middleware _requestBodySizeLimitMiddleware(int maxBytes) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.contentLength != null && request.contentLength! > maxBytes) {
        return Response(
          payloadTooLargeError,
          body: 'Request body too large',
          headers: {'Content-Type': 'text/plain'},
        );
      }

      return innerHandler(request);
    };
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
  Persistence persistence,
  Persistence errorPersistence,
) async {
  log.info('Shutting down...');
  await serverv4.close(force: true);
  await serverv6.close(force: true);
  await persistence.close();
  await errorPersistence.close();
}
