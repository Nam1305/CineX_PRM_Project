import 'package:cinex_application/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService configuration', () {
    test('uses the deployed OData API endpoint', () {
      final baseUri = Uri.parse(ApiService.baseUrl);

      expect(baseUri.scheme, 'https');
      expect(baseUri.host, 'cinex-api.onrender.com');
      expect(baseUri.path, '/odata');
    });
  });
}
