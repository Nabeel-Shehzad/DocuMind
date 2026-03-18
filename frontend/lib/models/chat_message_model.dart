class ChatMessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<Map<String, dynamic>> sources; // only for bot messages
  final bool isStreaming; // true while token stream is active

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.sources    = const [],
    this.isStreaming = false,
  });

  ChatMessageModel copyWith({
    String?                      content,
    bool?                        isStreaming,
    List<Map<String, dynamic>>?  sources,
  }) =>
      ChatMessageModel(
        id:          id,
        role:        role,
        timestamp:   timestamp,
        content:     content    ?? this.content,
        isStreaming: isStreaming ?? this.isStreaming,
        sources:     sources    ?? this.sources,
      );

  bool get isUser => role == MessageRole.user;
  bool get isBot  => role == MessageRole.assistant;

  // Converts to format expected by backend chat_history
  Map<String, dynamic> toHistoryJson() => {
    'role':    role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
  };
}

enum MessageRole { user, assistant }
