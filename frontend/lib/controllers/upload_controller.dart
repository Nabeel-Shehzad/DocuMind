import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../models/document_model.dart';
import '../core/services/api_service.dart';
import 'document_controller.dart';

enum UploadStage { idle, picking, uploading, extracting, chunking, embedding, done, error }

class UploadController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  // ── Observable state ──────────────────────────────────────────────────────
  final stage         = UploadStage.idle.obs;
  final pickedFileName = ''.obs;
  final pickedFilePath = ''.obs;
  final errorMsg       = ''.obs;
  final uploadedDoc    = Rxn<DocumentModel>();

  // ── Stage labels shown in the progress UI ─────────────────────────────────
  static const stageLabels = {
    UploadStage.idle:       'Pick a document to get started',
    UploadStage.picking:    'Opening file picker...',
    UploadStage.uploading:  'Uploading file...',
    UploadStage.extracting: 'Extracting text from document...',
    UploadStage.chunking:   'Splitting into chunks...',
    UploadStage.embedding:  'Creating embeddings...',
    UploadStage.done:       'Document ready!',
    UploadStage.error:      'Something went wrong',
  };

  String get stageLabel => stageLabels[stage.value] ?? '';

  bool get isProcessing => stage.value != UploadStage.idle &&
      stage.value != UploadStage.done &&
      stage.value != UploadStage.error;

  // ── Pick file ─────────────────────────────────────────────────────────────
  Future<void> pickFile() async {
    stage(UploadStage.picking);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) {
      stage(UploadStage.idle);
      return;
    }

    final file = result.files.single;
    pickedFileName(file.name);
    pickedFilePath(file.path ?? '');
    stage(UploadStage.idle);
  }

  // ── Upload + ingest ───────────────────────────────────────────────────────
  Future<void> uploadFile() async {
    if (pickedFilePath.value.isEmpty) return;

    errorMsg('');
    uploadedDoc.value = null;

    try {
      // Simulate pipeline stage progression (visual feedback)
      stage(UploadStage.uploading);
      await Future.delayed(const Duration(milliseconds: 300));

      stage(UploadStage.extracting);
      await Future.delayed(const Duration(milliseconds: 400));

      stage(UploadStage.chunking);

      // The actual upload — backend runs the full pipeline
      final res = await _api.uploadDocument(
        pickedFilePath.value,
        pickedFileName.value,
      );

      stage(UploadStage.embedding);
      await Future.delayed(const Duration(milliseconds: 500));

      final doc = DocumentModel.fromJson(res.data as Map<String, dynamic>);
      uploadedDoc.value = doc;

      // Add to document list
      Get.find<DocumentController>().addDocument(doc);

      stage(UploadStage.done);
    } catch (e) {
      errorMsg('Upload failed: $e');
      stage(UploadStage.error);
    }
  }

  // ── Reset for another upload ──────────────────────────────────────────────
  void reset() {
    stage(UploadStage.idle);
    pickedFileName('');
    pickedFilePath('');
    errorMsg('');
    uploadedDoc.value = null;
  }
}
