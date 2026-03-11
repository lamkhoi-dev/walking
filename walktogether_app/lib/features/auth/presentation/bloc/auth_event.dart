/// Base class for auth events
abstract class AuthEvent {}

/// Check auth status on app start
class AuthCheckRequested extends AuthEvent {}

/// Login with identifier (email/phone) and password
class AuthLoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  AuthLoginRequested({
    required this.identifier,
    required this.password,
  });
}

/// Register as a new member
class AuthRegisterRequested extends AuthEvent {
  final String? email;
  final String? phone;
  final String password;
  final String fullName;
  final String? companyCode;

  AuthRegisterRequested({
    this.email,
    this.phone,
    required this.password,
    required this.fullName,
    this.companyCode,
  });
}

/// Logout
class AuthLogoutRequested extends AuthEvent {}

/// Poll company status (for pending approval)
class AuthCompanyStatusCheckRequested extends AuthEvent {}
