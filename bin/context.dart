import 'dart:io';

import 'main.dart';

SecurityContext createSecurityContext() {
  final SecurityContext context = SecurityContext();

  try {
    context.useCertificateChain(certPath);
    context.usePrivateKey(keyPath);
  } catch (e) {
    print('[Error] $e');
    exit(exitFailure);
  }

  return context;
}
