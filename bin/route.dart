import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'hallucinate.dart';
import 'responsecache.dart';

class RouteHandler {
  late final String cacheRobotsTxt;
  late final Router _router;
  final Logger? _logger;
  final Hallucinate? _hallucinate;
  final ResponseCache? _responseCache;

  String? _cachedHomePage;
  DateTime? _cacheTime;
  bool _isRefreshingCache = false;

  RouteHandler({
    Logger? logger,
    Hallucinate? hallucinate,
    ResponseCache? responseCache,
  }) : _logger = logger,
       _hallucinate = hallucinate,
       _responseCache = responseCache;

  Future<void> init() async {
    await _initRobotsCache();

    _router =
        Router()
          ..get('/', _homeHandler)
          ..get('/healthcheck', _healthcheckHandler)
          ..get(
            '/robots.txt',
            (Request req) => Response.ok(
              cacheRobotsTxt,
              headers: {'Cache-Control': 'public, max-age=3600'},
            ),
          )
          ..get(
            '/private',
            (Request req) => Response.forbidden(
              'Not cool, you were told to not visit this page.',
            ),
          )
          ..get(
            '/<catchAll|.*>',
            (Request req) async => await _catchAllHandler(req),
          );
  }

  Router get router => _router;

  Future<Response> _homeHandler(Request req) async {
    if (_cachedHomePage != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < cacheExpiry) {
      return Response.ok(
        _cachedHomePage!,
        headers: {'Cache-Control': 'no-store'},
      );
    }

    // If another request is already refreshing
    // return stale cache or empty
    if (_isRefreshingCache) {
      return Response.ok(
        _cachedHomePage ?? 'Loading...',
        headers: {'Cache-Control': 'no-store'},
      );
    }

    _isRefreshingCache = true;

    try {
      final logTail = await _readLogTail();

      final buffer =
          StringBuffer()
            ..writeln('People and bots have visited following pages:\n')
            ..writeln('Level,DateTime,Method,Path');

      for (final line in logTail.split('\n')) {
        if (line.isEmpty) continue;

        final segmentFromCSV = line.split(',');
        if (segmentFromCSV.length >= 4) {
          String method = segmentFromCSV[2];
          String path = segmentFromCSV[3];

          try {
            method = Uri.decodeComponent(method);
          } catch (e) {
            // Keep encoded if decoding fails
            _logger?.warning('Failed to decode method URI component: $e');
          }

          try {
            path = Uri.decodeComponent(path);
          } catch (e) {
            // Keep encoded if decoding fails
            _logger?.warning('Failed to decode path URI component: $e');
          }

          final decoded =
              '${segmentFromCSV[0]},${segmentFromCSV[1]},$method,$path';
          buffer.writeln(decoded);
        } else {
          buffer.writeln(line);
        }
      }

      _cachedHomePage = buffer.toString();
      _cacheTime = DateTime.now();

      return Response.ok(
        _cachedHomePage!,
        headers: {'Cache-Control': 'no-store'},
      );
    } finally {
      _isRefreshingCache = false;
    }
  }

  Future<String> _readLogTail({int maxLines = maxLinesToRead}) async {
    final allLines = <String>[];
    int totalBytesRead = 0;

    final logFiles = await _getLogFilesInReverseOrder();

    for (final logFile in logFiles) {
      if (!await logFile.exists()) continue;
      if (totalBytesRead >= maxReadBytes) break;

      final fileLines = await _readLogFileTail(
        logFile,
        maxLines - allLines.length,
      );
      allLines.insertAll(0, fileLines);
      totalBytesRead += fileLines.join('\n').length;

      if (allLines.length >= maxLines) break;
    }

    // Only the most recent lines
    if (allLines.length > maxLines) {
      return allLines.sublist(allLines.length - maxLines).join('\n');
    }

    return allLines.join('\n');
  }

  Future<List<File>> _getLogFilesInReverseOrder() async {
    final files = <File>[];

    for (int i = maxRotatedLogFiles; i >= 1; i--) {
      final rotatedFile = File('$logFileName.$i');

      if (await rotatedFile.exists()) {
        files.add(rotatedFile);
      }
    }

    files.add(File(logFileName));

    return files;
  }

  Future<List<String>> _readLogFileTail(File file, int maxLines) async {
    if (!await file.exists()) return [];

    final raf = await file.open();
    try {
      final List<int> buffer = [];
      int position = await raf.length();
      int bytesRead = 0;

      while (position > 0 && bytesRead < maxReadBytes) {
        final readSize = position >= chunkSize ? chunkSize : position;
        position -= readSize;
        bytesRead += readSize;

        await raf.setPosition(position);
        buffer.insertAll(0, await raf.read(readSize));

        final lines = const LineSplitter().convert(utf8.decode(buffer));
        if (lines.length > maxLines) {
          return lines.sublist(lines.length - maxLines);
        }
      }

      return const LineSplitter().convert(utf8.decode(buffer));
    } finally {
      await raf.close();
    }
  }

  Response _healthcheckHandler(Request req) {
    return Response.ok('Healthy');
  }

  Future<Response> _catchAllHandler(Request req) async {
    final requestPath = req.requestedUri.path.toString();

    if (_responseCache != null) {
      final cachedResponse = _responseCache.get(requestPath);

      if (cachedResponse != null) {
        return Response.ok(
          cachedResponse,
          headers: {'Content-type': 'text/plain'},
          encoding: Encoding.getByName('utf8'),
        );
      }
    }

    if (_hallucinate != null) {
      try {
        final hallucinatedContent = await _hallucinate.generate(requestPath);

        if (hallucinatedContent != null) {
          if (_responseCache != null) {
            await _responseCache.put(requestPath, hallucinatedContent);
          }

          return Response.ok(
            hallucinatedContent.toString(),
            headers: {'Content-type': 'text/plain'},
            encoding: Encoding.getByName('utf8'),
          );
        }
      } catch (e) {
        _logger?.warning('Failed to generate hallucinated response: $e');
      }
    }

    return Response.notFound('404 Not Found');
  }

  Future<void> _initRobotsCache() async {
    try {
      cacheRobotsTxt = await File(robotsTxtFile).readAsString();
    } catch (e) {
      _logger?.severe('Failed to read robots.txt file: $e');
      throw FileSystemException(
        'File "robots.txt" not found. Have to be in same directory.',
      );
    }
  }
}
