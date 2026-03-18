import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/upload_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../app/routes.dart';
import 'widgets/pipeline_progress.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Obx(() {
        final stage = controller.stage.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── File picker zone ────────────────────────────────────
              GestureDetector(
                onTap: controller.isProcessing ? null : controller.pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height:  160,
                  decoration: BoxDecoration(
                    color:  AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: controller.pickedFilePath.value.isNotEmpty
                          ? AppColors.primary
                          : AppColors.bgCardLight,
                      width: 2,
                    ),
                  ),
                  child: controller.pickedFilePath.value.isNotEmpty
                      ? _PickedFileDisplay(
                          name: controller.pickedFileName.value)
                      : const _PickerPlaceholder(),
                ),
              ),

              const SizedBox(height: 32),

              // ── Pipeline progress (visible while processing or done) ─
              if (stage != UploadStage.idle) ...[
                const Text(
                  'Pipeline Progress',
                  style: TextStyle(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.bgCardLight),
                  ),
                  child: PipelineProgress(currentStage: stage),
                ),
                const SizedBox(height: 24),
              ],

              // ── Error message ───────────────────────────────────────
              if (controller.errorMsg.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(controller.errorMsg.value,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),

              // ── Success state ───────────────────────────────────────
              if (stage == UploadStage.done) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${controller.pickedFileName.value} ingested! '
                          '${controller.uploadedDoc.value?.chunkCount ?? 0} chunks ready.',
                          style: const TextStyle(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.reset,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Upload Another',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final doc = controller.uploadedDoc.value;
                        if (doc != null) {
                          Get.offNamedUntil(AppRoutes.home, (r) => false);
                          Get.toNamed(AppRoutes.chat, arguments: doc);
                        }
                      },
                      child: const Text('Chat Now'),
                    ),
                  ),
                ]),
              ]

              // ── Upload button ───────────────────────────────────────
              else if (!controller.isProcessing) ...[
                ElevatedButton.icon(
                  onPressed: controller.pickedFilePath.value.isEmpty
                      ? null
                      : controller.uploadFile,
                  icon:  const Icon(Icons.rocket_launch),
                  label: const Text('Process Document'),
                ),
                if (controller.pickedFilePath.value.isEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Pick a PDF or image first',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _PickerPlaceholder extends StatelessWidget {
  const _PickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file, color: AppColors.primary, size: 48),
        SizedBox(height: 12),
        Text('Tap to pick a file',
            style: TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('PDF, PNG, JPG supported',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    );
  }
}

class _PickedFileDisplay extends StatelessWidget {
  final String name;
  const _PickedFileDisplay({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.insert_drive_file,
            color: AppColors.primary, size: 40),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Tap to change',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      ],
    );
  }
}
