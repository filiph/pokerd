import 'dart:io';

void main() async {
  final portStr = Platform.environment['PORT'] ?? '80';
  final port = int.tryParse(portStr) ?? 80;
  final redirectUrl = Platform.environment['REDIRECT_URL'] ?? 'https://filiph.net';

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Redirect server listening on port $port');
  print('Redirecting all requests to: $redirectUrl');

  await for (final HttpRequest request in server) {
    try {
      request.response
        ..statusCode = HttpStatus.movedPermanently
        ..headers.set(HttpHeaders.locationHeader, redirectUrl)
        ..close();
    } catch (e, stack) {
      print('Error processing request: $e\n$stack');
    }
  }
}
