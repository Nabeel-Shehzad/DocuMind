import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import '../../controllers/summary_controller.dart';
import '../../models/document_model.dart';
import '../../models/summary_model.dart';
import '../../core/theme/app_theme.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doc        = Get.arguments as DocumentModel;
    final controller = Get.find<SummaryController>();
    controller.init(doc);

    return Scaffold(
      appBar: AppBar(title: Text('Summary — ${doc.shortName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Type selector grid ─────────────────────────────────
            GridView.count(
              crossAxisCount:   2,
              shrinkWrap:       true,
              crossAxisSpacing: 12,
              mainAxisSpacing:  12,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: SummaryType.all.map((type) => Obx(() {
                final selected =
                    controller.selectedType.value == type.value;
                return GestureDetector(
                  onTap: () => controller.selectType(type.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withAlpha(40)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.bgCardLight,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(type.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  type.description,
                                  style: const TextStyle(
                                    color:    AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })).toList(),
            ),

            const SizedBox(height: 20),

            // ── Generate button ────────────────────────────────────
            Obx(() => ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.generateSummary,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(controller.isLoading.value
                  ? 'Generating...'
                  : 'Generate Summary'),
            )),

            const SizedBox(height: 24),

            // ── Error ──────────────────────────────────────────────
            Obx(() {
              if (controller.errorMsg.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Text(controller.errorMsg.value,
                    style:
                        const TextStyle(color: AppColors.error)),
              );
            }),

            // ── Result ────────────────────────────────────────────
            Obx(() {
              final summary = controller.summary.value;
              if (summary == null) return const SizedBox.shrink();
              return _SummaryResult(summary: summary);
            }),
          ],
        ),
      ),
    );
  }
}

class _SummaryResult extends StatelessWidget {
  final SummaryModel summary;
  const _SummaryResult({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                SummaryType.all
                    .firstWhere((t) => t.value == summary.summaryType)
                    .label,
                style: const TextStyle(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: AppColors.bgCardLight, height: 24),

          // Content
          MarkdownBody(
            data: summary.summary,
            styleSheet: MarkdownStyleSheet(
              p:      const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.6),
              h2:     const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize:   16),
              listBullet: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14),
              strong: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
