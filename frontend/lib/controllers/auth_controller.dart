import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/routes.dart';

class AuthController extends GetxController {
  final _supabase = Supabase.instance.client;

  // ── Observables ─────────────────────────────────────────────────────────────
  final RxBool  isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Getters ──────────────────────────────────────────────────────────────────
  User?   get currentUser    => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  String? get accessToken    => currentSession?.accessToken;
  bool    get isLoggedIn     => currentUser != null;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Listen for auth state changes (token refresh, logout, etc.)
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Get.offAllNamed(AppRoutes.home);
      } else if (event == AuthChangeEvent.signedOut) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  // ── Auth Methods ─────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    isLoading.value  = true;
    errorMessage.value = '';
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Navigation handled by auth state listener above
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Unexpected error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password) async {
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      final res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user != null && res.session == null) {
        // Email confirmation required
        errorMessage.value = 'Check your email to confirm your account.';
      }
      // If session returned immediately, auth state listener navigates
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Unexpected error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    // Navigation handled by auth state listener
  }
}
