import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../models/document_model.dart';
import '../core/services/sse_service.dart';

class ChatController extends GetxController {
  final SSEService _sse = Get.find<SSEService>();
  final _uuid = const Uuid();

  // ── Observable state ──────────────────────────────────────────────────────
  final messages    = <ChatMessageModel>[].obs;
  final isStreaming = false.obs;
  final errorMsg    = ''.obs;

  late DocumentModel document;
  final scrollController = ScrollController();
  final inputController  = TextEditingController();

  void init(DocumentModel doc) {
    document = doc;
    messages.clear();
    // Greeting message
    messages.add(ChatMessageModel(
      id:        _uuid.v4(),
      role:      MessageRole.assistant,
      content:   'Hi! I\'ve read **${doc.filename}** (${doc.pageCount} pages, '
                 '${doc.chunkCount} chunks indexed). Ask me anything about it!',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void onClose() {
    scrollController.dispose();
    inputController.dispose();
    super.onClose();
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isStreaming.value) return;

    errorMsg('');
    inputController.clear();

    // 1. Add user message
    final userMsg = ChatMessageModel(
      id:        _uuid.v4(),
      role:      MessageRole.user,
      content:   text.trim(),
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    _scrollToBottom();

    // 2. Add empty bot message (will fill via stream)
    final botId = _uuid.v4();
    final botMsg = ChatMessageModel(
      id:          botId,
      role:        MessageRole.assistant,
      content:     '',
      timestamp:   DateTime.now(),
      isStreaming: true,
    );
    messages.add(botMsg);
    isStreaming(true);

    // 3. Build chat history (exclude current bot placeholder)
    final history = messages
        .where((m) => m.id != botId && m.content.isNotEmpty)
        .map((m) => m.toHistoryJson())
        .toList();

    // 4. Stream response
    final buffer = StringBuffer();
    List<Map<String, dynamic>> sources = [];

    try {
      await for (final event in _sse.streamChat(
        documentId:  document.documentId,
        question:    text.trim(),
        chatHistory: history,
      )) {
        switch (event.type) {
          case SSEEventType.sources:
            sources = event.sources;
            break;

          case SSEEventType.token:
            buffer.write(event.data);
            _updateBotMessage(botId, buffer.toString(), sources: sources);
            _scrollToBottom();
            break;

          case SSEEventType.done:
            break;
        }
      }
    } catch (e) {
      errorMsg('Stream error: $e');
      _updateBotMessage(botId, 'Sorry, something went wrong. Please try again.');
    } finally {
      // Mark streaming done
      _updateBotMessage(
        botId,
        buffer.toString().isEmpty ? 'No response received.' : buffer.toString(),
        sources:     sources,
        isStreaming: false,
      );
      isStreaming(false);
      _scrollToBottom();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateBotMessage(
    String id,
    String content, {
    List<Map<String, dynamic>> sources = const [],
    bool isStreaming = true,
  }) {
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    messages[idx] = messages[idx].copyWith(
      content:     content,
      sources:     sources,
      isStreaming: isStreaming,
    );
    messages.refresh();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    messages.clear();
    init(document);
  }
}
