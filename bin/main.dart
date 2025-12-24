import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:logging/logging.dart';
import 'routes.dart';
import 'log.dart';
import 'persistence.dart';

const logFileName = 'logpot-logs.txt';
const errorLogFileName = 'logpot-errors.txt';
const exitSuccess = 0;

Future<void> main() async {
  final logWrapper = Log("Global");
  final Logger log = logWrapper.logger;

  final persistence = await Persistence.createFile(logFileName);
  final errorPersistence = await Persistence.createFile(errorLogFileName);

  logWrapper.addOutput(persistence.log);
  logWrapper.addErrorOutput(errorPersistence.log);

  final handler = Pipeline().addHandler((request) {
    if (request.requestedUri.path != '/') {
      log.info('${request.method} ${request.requestedUri.path}');
    }

    return router.call(request);
  });

  final ipv4 = InternetAddress.anyIPv4;
  final ipv6 = InternetAddress.anyIPv6;

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final serverv4 = await serve(handler, ipv4, port);
  final serverv6 = await serve(handler, ipv6, port);

  registerSignalHandler(() async {
    log.info('Shutting down...');
    await serverv4.close(force: true);
    await serverv6.close(force: true);
    await logWrapper.dispose();
    await persistence.close();
    await errorPersistence.close();
  });

  log.info("""
  \nServer listening on:
  http://${serverv4.address.address}:${serverv4.port}
  http://${serverv6.address.address}:${serverv6.port}
""");
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
