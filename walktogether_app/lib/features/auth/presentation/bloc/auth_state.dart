import '../../data/models/user_model.dart';
import '../../data/models/company_model.dart';

/// Base class for auth states
abstract class AuthState {}

/// Initial state — checking auth
class AuthInitial extends AuthState {}

/// Loading state (login/register in progress)
class AuthLoading extends AuthState {}

/// Authenticated with approved company (or super_admin)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final CompanyModel? company;

  AuthAuthenticated({required this.user, this.company});
}

/// Company pending approval
class AuthPendingApproval extends AuthState {
  final UserModel user;
  final CompanyModel company;

  AuthPendingApproval({required this.user, required this.company});
}

/// Company was rejected
class AuthCompanyRejected extends AuthState {
  final UserModel user;
  final CompanyModel company;

  AuthCompanyRejected({required this.user, required this.company});
}

/// Company was suspended
class AuthCompanySuspended extends AuthState {
  final UserModel user;
  final CompanyModel company;

  AuthCompanySuspended({required this.user, required this.company});
}

/// Not authenticated
class AuthUnauthenticated extends AuthState {}

/// Error during auth operation
class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}
