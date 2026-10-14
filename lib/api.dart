
class Api {
  static const String baseUrl =
      'https://receitasapi-b-2025.vercel.app/';

  static String getEndPoint(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
