import 'dart:async';
import 'dart:io';

class Persistence {
  late String _path;
  late IOSink _sink;
  StreamSubscription<FileSystemEvent>? _fileWatcher;
  bool _reopening = false;

  Persistence(String path, IOSink sink) {
    _path = path;
    _sink = sink;
  }

  static Future<Persistence> createFile(String path) async {
    final file = File(path);
    await file.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);

    final persistence = Persistence(file.absolute.path, sink);
    persistence._startWatcher();

    return persistence;
  }

  void _startWatcher() {
    final directory = File(_path).parent;

    _fileWatcher = directory
        .watch(events: FileSystemEvent.delete | FileSystemEvent.move)
        .listen((event) async {
          final eventPath = File(event.path).absolute.path;
          final watchedPath = File(_path).absolute.path;

          final wasDeletedOrMoved =
              event is FileSystemDeleteEvent || event is FileSystemMoveEvent;

          if (wasDeletedOrMoved && eventPath == watchedPath) {
            await _reopenSink();
          }
        });
  }

  void log(String data) {
    _sink.writeln(data);
  }

  Future<void> close() async {
    await _fileWatcher?.cancel();
    await _sink.flush();
    await _sink.close();
  }

  Future<void> _reopenSink() async {
    if (_reopening) return;
    _reopening = true;

    try {
      await _sink.flush();
      await _sink.close();

      final file = File(_path);
      await file.create(recursive: true);
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      // If reopening fails, not much can do
      // continue with old sink or ignore
      print('Error reopening log file: $e');
    } finally {
      _reopening = false;
    }
  }
}
