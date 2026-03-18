import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/sse_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/document_controller.dart';
import '../controllers/upload_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/summary_controller.dart';

/// InitialBinding — runs once at app startup.
/// Registers services and controllers as permanent singletons.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Auth (must be first — others depend on it)
    Get.put<AuthController>(AuthController(), permanent: true);

    // Services
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<SSEService>(SSEService(), permanent: true);

    // Controllers
    Get.put<DocumentController>(DocumentController(), permanent: true);
    Get.put<UploadController>(UploadController(),   permanent: true);
    Get.put<ChatController>(ChatController(),         permanent: true);
    Get.put<SummaryController>(SummaryController(), permanent: true);
  }
}
