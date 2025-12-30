import 'dart:io';

import 'package:logging/logging.dart';

import 'persistence.dart';
import 'responsecache.dart';
import 'log.dart';
import 'config.dart';

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
  HttpServer server,
  Log loggerConfig,
  Persistence persistence,
  Persistence errorPersistence,
  Persistence privatePersistence,
  ResponseCache? responseCache,
) async {
  print('Shutting down...');
  await server.close(force: true);
  await loggerConfig.dispose();
  await persistence.close();
  await errorPersistence.close();
  await privatePersistence.close();
  await responseCache?.close();
}
