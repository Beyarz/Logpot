import 'dart:async';
import 'dart:io';
import 'dart:collection';

import 'config.dart';

class Persistence {
  final String _path;
  late IOSink _sink;

  StreamSubscription<FileSystemEvent>? _fileWatcher;
  bool _reopening = false;

  final int _maxSizeBytes;
  int _currentSizeBytes = 0;
  final Queue<String> _pendingWrites = Queue<String>();
  bool _isRotating = false;

  Persistence(
    String path,
    IOSink sink, {
    int maxSizeBytes = defaultMaxSizeBytes,
  }) : _path = path,
       _sink = sink,
       _maxSizeBytes = maxSizeBytes;

  static Future<Persistence> createFile(
    String path, {
    int maxSizeBytes = defaultMaxSizeBytes,
  }) async {
    final file = File(path);
    await file.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);

    final persistence = Persistence(
      file.absolute.path,
      sink,
      maxSizeBytes: maxSizeBytes,
    );
    persistence._startWatcher();
    await persistence._initializeCurrentSize();

    return persistence;
  }

  Future<void> _initializeCurrentSize() async {
    try {
      final file = File(_path);

      if (await file.exists()) {
        _currentSizeBytes = await file.length();
      }
    } catch (e) {
      _currentSizeBytes = 0;
    }
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
    if (_isRotating) {
      _pendingWrites.add(data);
      return;
    }

    try {
      final line = '$data\n';
      _sink.write(line);
      _currentSizeBytes += line.length;

      if (_currentSizeBytes >= _maxSizeBytes) {
        _isRotating = true;
        Timer.run(() => _rotateLog());
      }
    } catch (e) {
      print('Log write failed: $e');
    }
  }

  Future<void> _rotateLog() async {
    if (_reopening) return;
    _reopening = true;

    try {
      await _sink.flush();
      await _sink.close();

      for (int i = maxRotatedLogFiles - 1; i > 0; i--) {
        final olderFile = File('$_path.$i');
        final newerFile = File('$_path.${i - 1}');

        if (await newerFile.exists()) {
          if (await olderFile.exists()) {
            await olderFile.delete();
          }

          await newerFile.rename(olderFile.path);
        }
      }

      final currentFile = File(_path);
      final rotatedFile = File('$_path.1');

      if (await currentFile.exists()) {
        if (await rotatedFile.exists()) {
          await rotatedFile.delete();
        }

        await currentFile.rename(rotatedFile.path);
      }

      final newFile = File(_path);
      await newFile.create(recursive: true);
      _sink = newFile.openWrite(mode: FileMode.append);

      _currentSizeBytes = 0;
    } catch (e) {
      print('Error rotating log file: $e');

      try {
        final file = File(_path);
        await file.create(recursive: true);
        _sink = file.openWrite(mode: FileMode.append);
        _currentSizeBytes = 0;
      } catch (_) {
        // If we can't reopen
        // there's not much can do
      }
    } finally {
      _reopening = false;
    }
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
