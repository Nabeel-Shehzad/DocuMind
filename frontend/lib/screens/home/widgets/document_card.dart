import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/document_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';
import '../../../controllers/document_controller.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  const DocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(document.typeIcon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.shortName,
                        style: const TextStyle(
                          color:      AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize:   15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.pageCount} pages • '
                        '${document.chunkCount} chunks • '
                        '${DateFormat('MMM d, yyyy').format(document.uploadedAt)}',
                        style: const TextStyle(
                          color:    AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon:  Icons.chat_bubble_outline,
                    label: 'Chat',
                    color: AppColors.primary,
                    onTap: () => Get.toNamed(
                      AppRoutes.chat,
                      arguments: document,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon:  Icons.summarize_outlined,
                    label: 'Summary',
                    color: AppColors.info,
                    onTap: () => Get.toNamed(
                      AppRoutes.summary,
                      arguments: document,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Document',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove "${document.shortName}" and all its embeddings?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<DocumentController>().deleteDocument(document.documentId);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
