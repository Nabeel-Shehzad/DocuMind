import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/document_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../app/routes.dart';
import 'widgets/document_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DocumentController>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧠', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('DocuMind AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.fetchDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: Obx(() {
        // Loading skeleton
        if (controller.isLoading.value && controller.documents.isEmpty) {
          return _LoadingSkeleton();
        }

        // Error state
        if (controller.errorMsg.value.isNotEmpty) {
          return _ErrorView(
            message: controller.errorMsg.value,
            onRetry: controller.fetchDocuments,
          );
        }

        // Empty state
        if (controller.documents.isEmpty) {
          return const _EmptyState();
        }

        // Document list
        return RefreshIndicator(
          onRefresh: controller.fetchDocuments,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.documents.length,
            itemBuilder: (_, i) =>
                DocumentCard(document: controller.documents[i]),
          ),
        );
      }),

      // Upload FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.upload),
        backgroundColor: AppColors.primary,
        icon:  const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:     AppColors.bgCard,
      highlightColor: AppColors.bgCardLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📂', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          const Text(
            'No documents yet',
            style: TextStyle(
              color:      AppColors.textPrimary,
              fontSize:   22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a PDF or image to get started',
            style: TextStyle(color: AppColors.textHint),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.upload),
            icon:  const Icon(Icons.upload_file),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 56),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
