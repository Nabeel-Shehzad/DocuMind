class ApiConfig {
  // Change this to your machine's IP when testing on a physical device
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Document endpoints
  static const String uploadDocument  = '/documents/upload';
  static const String listDocuments   = '/documents/';
  static String getDocument(String id)    => '/documents/$id';
  static String deleteDocument(String id) => '/documents/$id';

  // Chat endpoints
  static const String chat    = '/chat/';
  static const String summary = '/chat/summary';

  // Timeouts
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 60000;
}
