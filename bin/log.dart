import 'dart:async';

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

typedef LogOutput = FutureOr<void> Function(String message);

class Log {
  final StreamController<String> _fanOut = StreamController.broadcast();
  final StreamController<String> _privateFanOut = StreamController.broadcast();
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

        print(
          'Internal logging error: $errorLog',
        ); // Fallback for internal errors
        await _emitError(errorLog);
      }
    });
  }

  void addPrivateOutput(LogOutput subscriber) {
    late final StreamSubscription<String> subscription;

    subscription = _privateFanOut.stream.listen((msg) async {
      try {
        await subscriber(msg);
      } catch (err, stack) {
        // Remove the broken sink
        await subscription.cancel();

        final timestamp = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(DateTime.now());

        final errorLog =
            '[$timestamp] Private log ${subscriber.runtimeType} failed\nERROR: $err\nSTACK: $stack';

        print(
          'Internal logging error: $errorLog',
        ); // Fallback for internal errors
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
      } catch (e) {
        // Nothing else I can do
        // I just want to avoid infinite recursion
        print('Critical: Error output failed: $e');
      }
    }
  }

  void _startListener() {
    _logger.onRecord.listen((record) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(record.time);
      final formattedMessage =
          '[${record.level.name}],$timestamp,${record.message}';

      if (record.level == Level.SHOUT) {
        _fanOut.add(formattedMessage);
      } else if (record.level == Level.INFO) {
        _privateFanOut.add(formattedMessage);
      } else {
        _emitError(formattedMessage);
      }
    });
  }

  Future<void> dispose() async {
    await _fanOut.close();
    await _privateFanOut.close();
  }

  Logger get logger => _logger;
}
