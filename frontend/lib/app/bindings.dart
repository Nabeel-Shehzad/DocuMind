import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/sse_service.dart';
import '../controllers/document_controller.dart';
import '../controllers/upload_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/summary_controller.dart';

/// InitialBinding — runs once at app startup.
/// Registers services and controllers as permanent singletons.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services (permanent — live for the entire app lifetime)
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<SSEService>(SSEService(), permanent: true);

    // Controllers (permanent)
    Get.put<DocumentController>(DocumentController(), permanent: true);
    Get.put<UploadController>(UploadController(),   permanent: true);
    Get.put<ChatController>(ChatController(),         permanent: true);
    Get.put<SummaryController>(SummaryController(), permanent: true);
  }
}
