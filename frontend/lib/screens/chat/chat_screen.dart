import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../models/document_model.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doc        = Get.arguments as DocumentModel;
    final controller = Get.find<ChatController>();
    controller.init(doc);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(doc.shortName,
                style: const TextStyle(fontSize: 15)),
            Text(
              '${doc.pageCount} pages • ${doc.chunkCount} chunks',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────────
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: controller.messages.length,
              itemBuilder: (_, i) =>
                  MessageBubble(message: controller.messages[i]),
            )),
          ),

          // ── Error bar ──────────────────────────────────────────────
          Obx(() {
            if (controller.errorMsg.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: AppColors.error.withAlpha(30),
              child: Text(
                controller.errorMsg.value,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            );
          }),

          // ── Input bar ──────────────────────────────────────────────
          _ChatInputBar(controller: controller),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final ChatController controller;
  const _ChatInputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.bgCardLight)),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: controller.inputController,
              maxLines:   null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText:        'Ask anything about the document...',
                hintStyle:       TextStyle(color: AppColors.textHint),
                border:          InputBorder.none,
                enabledBorder:   InputBorder.none,
                focusedBorder:   InputBorder.none,
                contentPadding:  EdgeInsets.zero,
              ),
              onSubmitted: (text) =>
                  controller.sendMessage(text),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: controller.isStreaming.value
                ? const SizedBox(
                    width: 42, height: 42,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => controller
                        .sendMessage(controller.inputController.text),
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withAlpha(25),
                    ),
                  ),
          )),
        ],
      ),
    );
  }
}
