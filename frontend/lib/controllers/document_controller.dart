import 'package:get/get.dart';
import '../models/document_model.dart';
import '../core/services/api_service.dart';

class DocumentController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  // ── Observable state ──────────────────────────────────────────────────────
  final documents  = <DocumentModel>[].obs;
  final isLoading  = false.obs;
  final errorMsg   = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
  }

  // ── Fetch all documents ───────────────────────────────────────────────────
  Future<void> fetchDocuments() async {
    isLoading(true);
    errorMsg('');
    try {
      final res = await _api.listDocuments();
      final list = (res.data as List<dynamic>)
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      documents.assignAll(list);
    } catch (e) {
      errorMsg('Failed to load documents: $e');
    } finally {
      isLoading(false);
    }
  }

  // ── Delete document ───────────────────────────────────────────────────────
  Future<void> deleteDocument(String documentId) async {
    try {
      await _api.deleteDocument(documentId);
      documents.removeWhere((d) => d.documentId == documentId);
      Get.snackbar(
        'Deleted',
        'Document removed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Add document after upload ─────────────────────────────────────────────
  void addDocument(DocumentModel doc) {
    documents.insert(0, doc); // newest first
  }
}
