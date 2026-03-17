import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import '../../data/models/company_model.dart';
import '../../../../core/network/api_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  Timer? _statusPollTimer;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthCompanyStatusCheckRequested>(_onCompanyStatusCheckRequested);
  }

  /// Check auth on app start
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final hasToken = await _authRepository.hasToken();
      if (!hasToken) {
        emit(AuthUnauthenticated());
        return;
      }

      // Verify token by calling /auth/me with retry for cold start
      const maxRetries = 3;
      const retryDelays = [Duration(seconds: 5), Duration(seconds: 10), Duration(seconds: 20)];

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final result = await _authRepository.getMe();
          _emitAuthState(emit, result.user, result.company);
          return;
        } catch (e) {
          // Only clear tokens on 401 (invalid/expired token)
          if (e is UnauthorizedException) {
            await _authRepository.clearTokens();
            emit(AuthUnauthenticated());
            return;
          }

          // For timeout/network errors, retry (Render cold start can take 30-60s)
          if ((e is TimeoutException || e is NetworkException) &&
              attempt < maxRetries) {
            debugPrint('Auth check attempt ${attempt + 1} failed (${e.runtimeType}), retrying...');
            emit(AuthConnectingServer(
              attempt: attempt + 1,
              maxAttempts: maxRetries + 1,
            ));
            await Future.delayed(retryDelays[attempt]);
            continue;
          }

          // All retries exhausted or unknown error — still don't clear tokens
          debugPrint('Auth check failed after retries: $e');
          emit(AuthUnauthenticated());
          return;
        }
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  /// Login
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(
        LoginRequest(
          identifier: event.identifier,
          password: event.password,
        ),
      );
      _emitAuthState(emit, response.user, response.company);
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Register
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.register(
        RegisterRequest(
          email: event.email,
          phone: event.phone,
          password: event.password,
          fullName: event.fullName,
          companyCode: event.companyCode?.isNotEmpty == true
              ? event.companyCode
              : null,
        ),
      );
      _emitAuthState(emit, response.user, response.company);
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Logout
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _stopStatusPolling();
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  /// Poll company status
  Future<void> _onCompanyStatusCheckRequested(
    AuthCompanyStatusCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final company = await _authRepository.getCompanyStatus();
      final currentState = state;
      UserModel? user;

      if (currentState is AuthPendingApproval) {
        user = currentState.user;
      } else if (currentState is AuthCompanyRejected) {
        user = currentState.user;
      } else if (currentState is AuthCompanySuspended) {
        user = currentState.user;
      }

      if (user != null) {
        _emitAuthState(emit, user, company);
      }
    } catch (_) {
      // Silently fail — will retry on next poll
    }
  }

  /// Emit the appropriate auth state based on company status
  void _emitAuthState(
    Emitter<AuthState> emit,
    UserModel user,
    CompanyModel? company,
  ) {
    // Super admin has no company
    if (user.role == 'super_admin') {
      _stopStatusPolling();
      emit(AuthAuthenticated(user: user, company: company));
      return;
    }

    if (company == null) {
      emit(AuthAuthenticated(user: user));
      return;
    }

    switch (company.status) {
      case 'approved':
        _stopStatusPolling();
        emit(AuthAuthenticated(user: user, company: company));
        break;
      case 'pending':
        _startStatusPolling();
        emit(AuthPendingApproval(user: user, company: company));
        break;
      case 'rejected':
        _stopStatusPolling();
        emit(AuthCompanyRejected(user: user, company: company));
        break;
      case 'suspended':
        _stopStatusPolling();
        emit(AuthCompanySuspended(user: user, company: company));
        break;
      default:
        emit(AuthAuthenticated(user: user, company: company));
    }
  }

  /// Start polling company status every 30 seconds
  void _startStatusPolling() {
    _stopStatusPolling();
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => add(AuthCompanyStatusCheckRequested()),
    );
  }

  /// Stop polling
  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  @override
  Future<void> close() {
    _stopStatusPolling();
    return super.close();
  }
}
