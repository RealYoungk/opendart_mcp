import 'package:test/test.dart';
import 'package:opendart_mcp/opendart_mcp.dart';

void main() {
  group('OpenDartClient', () {
    test('throws when API key is missing', () {
      expect(
        () => createServer(apiKey: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('OpenDartException contains message', () {
      const e = OpenDartException('test error', dartStatus: '013');
      expect(e.toString(), contains('test error'));
      expect(e.dartStatus, equals('013'));
    });
  });
}
