import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../config/api_config.dart';

class ApiService extends GetxService {
  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeoutMs),
        headers:        {'Content-Type': 'application/json'},
      ),
    );

    // ── Auth interceptor — inject Bearer token on every request ──────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Supabase.instance.client.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // ── Debug logging ─────────────────────────────────────────────────────────
    _dio.interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
      error:        true,
    ));
  }

  // ── Documents ───────────────────────────────────────────────────────────────

  Future<Response> uploadDocument(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _dio.post(
      ApiConfig.uploadDocument,
      data: formData,
      options: Options(
        contentType:    'multipart/form-data',
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
  }

  Future<Response> listDocuments() => _dio.get(ApiConfig.listDocuments);

  Future<Response> deleteDocument(String id) =>
      _dio.delete(ApiConfig.deleteDocument(id));

  // ── Summary ─────────────────────────────────────────────────────────────────

  Future<Response> getSummary(String documentId, String summaryType) =>
      _dio.post(
        ApiConfig.summary,
        data: {'document_id': documentId, 'summary_type': summaryType},
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );

  // ── Raw Dio (used by SSE service) ────────────────────────────────────────────
  Dio get dio => _dio;
}
