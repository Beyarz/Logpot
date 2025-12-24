import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

class Log {
  late Logger _logger;

  Log(String className, {Level logLevel = Level.ALL}) {
    hierarchicalLoggingEnabled = true;
    _logger = Logger(className);
    _logger.level = logLevel;
    _startListener();
  }

  void _startListener() {
    _logger.onRecord.listen((record) {
      String timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss').format(record.time);
      print('[${record.level.name}] $timeFormat ${record.message}');
    });
  }

  Logger get getInstance {
    return _logger;
  }
}
