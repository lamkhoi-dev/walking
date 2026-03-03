/// Form validators
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Phone is optional
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  static String? companyCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mã công ty không được để trống';
    }
    if (value.trim().length != 6) {
      return 'Mã công ty phải có 6 ký tự';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().length < min) {
      return '$fieldName phải có ít nhất $min ký tự';
    }
    return null;
  }

  /// Email or Phone validator — user can use either
  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email hoặc số điện thoại';
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
