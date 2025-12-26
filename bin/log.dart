import 'dart:async';

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

typedef LogOutput = FutureOr<void> Function(String message);

class Log {
  final StreamController<String> _fanOut = StreamController.broadcast();
  final List<LogOutput> _errorOutputs = [];
  late final Logger _logger;

  Log(String scope, {Level level = Level.ALL}) {
    hierarchicalLoggingEnabled = true;
    _logger = Logger(scope)..level = level;
    _startListener();
  }

  void addOutput(LogOutput subscriber) {
    late final StreamSubscription<String> subscription;

    subscription = _fanOut.stream.listen((msg) async {
      try {
        await subscriber(msg);
      } catch (err, stack) {
        // Remove the broken sink
        await subscription.cancel();

        final timestamp = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(DateTime.now());

        final errorLog =
            '[$timestamp] Log ${subscriber.runtimeType} failed\nERROR: $err\nSTACK: $stack';

        await _emitError(errorLog);
      }
    });
  }

  void addErrorOutput(LogOutput subscriber) {
    _errorOutputs.add(subscriber);
  }

  Future<void> _emitError(String message) async {
    for (final sink in _errorOutputs) {
      try {
        await sink(message);
      } catch (_) {
        // Nothing else I can do
        // I just want to avoid infinite recursion
      }
    }
  }

  void _startListener() {
    _logger.onRecord.listen((record) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(record.time);
      _fanOut.add('[${record.level.name}],$timestamp,${record.message}');
    });
  }

  Future<void> dispose() async {
    await _fanOut.close();
  }

  Logger get logger => _logger;
}
