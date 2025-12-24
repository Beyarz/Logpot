import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final router = Router()..get('/', _rootHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}
