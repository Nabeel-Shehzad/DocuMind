import 'package:get/get.dart';
import '../models/document_model.dart';
import '../models/summary_model.dart';
import '../core/services/api_service.dart';

class SummaryController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  // ── Observable state ──────────────────────────────────────────────────────
  final selectedType = 'general'.obs;
  final isLoading    = false.obs;
  final errorMsg     = ''.obs;
  final summary      = Rxn<SummaryModel>();

  late DocumentModel document;

  void init(DocumentModel doc) {
    document = doc;
    summary.value = null;
    selectedType('general');
    errorMsg('');
  }

  void selectType(String type) {
    selectedType(type);
    summary.value = null; // clear previous result
  }

  // ── Generate summary ──────────────────────────────────────────────────────
  Future<void> generateSummary() async {
    isLoading(true);
    errorMsg('');
    summary.value = null;

    try {
      final res = await _api.getSummary(
        document.documentId,
        selectedType.value,
      );
      summary.value = SummaryModel.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      errorMsg('Failed to generate summary: $e');
    } finally {
      isLoading(false);
    }
  }
}
