import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../config/api_config.dart';
import 'api_service.dart';

/// Parses the Server-Sent Events stream from the /chat/ endpoint.
///
/// The backend sends:
///   event: sources  → JSON list of retrieved chunks
///   data: [token]   → streamed answer tokens
///   event: done     → stream ended
class SSEService extends GetxService {
  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Get.find<ApiService>().dio;
  }

  /// Returns a [Stream] that emits [SSEEvent] objects.
  Stream<SSEEvent> streamChat({
    required String documentId,
    required String question,
    required List<Map<String, dynamic>> chatHistory,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      ApiConfig.chat,
      data: {
        'document_id':  documentId,
        'question':     question,
        'chat_history': chatHistory,
      },
      options: Options(
        responseType:   ResponseType.stream,
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String? currentEvent;

    await for (final line in stream) {
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        final data = line.substring(5).trim();

        if (data == '[DONE]') {
          yield SSEEvent(type: SSEEventType.done, data: '');
          return;
        }

        if (currentEvent == 'sources') {
          try {
            final sources = jsonDecode(data) as List<dynamic>;
            yield SSEEvent(
              type:    SSEEventType.sources,
              data:    '',
              sources: sources.cast<Map<String, dynamic>>(),
            );
          } catch (_) {}
          currentEvent = null;
        } else {
          // Regular token — unescape newlines
          final token = data.replaceAll(r'\n', '\n');
          yield SSEEvent(type: SSEEventType.token, data: token);
        }
      }
    }
  }
}

// ── Event model ─────────────────────────────────────────────────────────────

enum SSEEventType { sources, token, done }

class SSEEvent {
  final SSEEventType type;
  final String data;
  final List<Map<String, dynamic>> sources;

  const SSEEvent({
    required this.type,
    required this.data,
    this.sources = const [],
  });
}
