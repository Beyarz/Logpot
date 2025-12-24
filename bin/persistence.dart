import 'dart:async';
import 'dart:io';

class Persistence {
  late IOSink _sink;

  Persistence(IOSink sink) {
    _sink = sink;
  }

  static Future<Persistence> createFile(String path) async {
    final sink = File(path).openWrite(mode: FileMode.append);
    return Persistence(sink);
  }

  void log(String data) {
    _sink.writeln(data);
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
