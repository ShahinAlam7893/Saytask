import 'package:flutter_dotenv/flutter_dotenv.dart';

class Urls {
  // static const String baseUrl = 'http://72.60.167.48:8004';
  static final String baseUrl = dotenv.env['apiendpoint'] ?? 'http://72.60.167.48:8004';
      // 'https://stockinged-penetrably-meri.ngrok-free.dev/';
}
