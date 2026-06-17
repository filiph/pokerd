import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Redirect Server Tests', () {
    Process? process;
    final port = '4040';
    final redirectUrl = 'https://filiph.net';

    setUp(() async {
      // Start the redirect server process
      process = await Process.start(
        'dart',
        ['bin/redirect.dart'],
        environment: {
          'PORT': port,
          'REDIRECT_URL': redirectUrl,
        },
      );
      // Wait a moment for the server to bind to the port
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      process?.kill();
      await process?.exitCode;
    });

    test('performs 301 redirect to target redirect URL', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:$port/any-path?with=params'));
      request.followRedirects = false; // Do not follow redirect so we can inspect headers
      
      final response = await request.close();
      
      expect(response.statusCode, equals(HttpStatus.movedPermanently));
      expect(response.headers.value(HttpHeaders.locationHeader), equals(redirectUrl));
    });
  });
}
