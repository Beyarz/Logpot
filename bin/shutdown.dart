import 'dart:io';

import 'package:logging/logging.dart';

import 'persistence.dart';
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
  HttpServer serverv4,
  HttpServer serverv6,
  Log loggerConfig,
  Persistence persistence,
  Persistence errorPersistence,
  Persistence privatePersistence,
) async {
  print('Shutting down...');
  await serverv4.close(force: true);
  await serverv6.close(force: true);
  await loggerConfig.dispose();
  await persistence.close();
  await errorPersistence.close();
  await privatePersistence.close();
}
