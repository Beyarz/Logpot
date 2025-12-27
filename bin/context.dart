import 'dart:io';
import 'package:logging/logging.dart';
import 'config.dart';

SecurityContext createSecurityContext({Logger? logger}) {
  final SecurityContext context = SecurityContext();

  try {
    context.useCertificateChain(certPath);
    context.usePrivateKey(keyPath);
  } catch (e) {
    logger?.severe(e);
    print(e);
    exit(exitFailure);
  }

  return context;
}
