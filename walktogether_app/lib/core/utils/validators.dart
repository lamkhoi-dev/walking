import 'package:easy_localization/easy_localization.dart';

/// Form validators
class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      final name = fieldName ?? 'validator.this_field'.tr();
      return 'validator.field_required'.tr(namedArgs: {'field': name});
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validator.email_required'.tr();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'validator.email_invalid'.tr();
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Phone is optional
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'validator.phone_invalid'.tr();
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'validator.password_required'.tr();
    }
    if (value.length < 6) {
      return 'validator.password_min_length'.tr();
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validator.confirm_password'.tr();
    }
    if (value != password) {
      return 'validator.password_mismatch'.tr();
    }
    return null;
  }

  static String? companyCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validator.company_code_required'.tr();
    }
    if (value.trim().length != 6) {
      return 'validator.company_code_length'.tr();
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.trim().length < min) {
      final name = fieldName ?? 'validator.this_field'.tr();
      return 'validator.min_length'.tr(namedArgs: {'field': name, 'min': '$min'});
    }
    return null;
  }

  /// Email or Phone validator — user can use either
  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validator.email_or_phone_required'.tr();
    }
    final v = value.trim();
    // Check if it looks like phone
    if (v.startsWith('0') || v.startsWith('+84')) {
      return phone(v);
    }
    // Otherwise validate as email
    return email(v);
  }
}
