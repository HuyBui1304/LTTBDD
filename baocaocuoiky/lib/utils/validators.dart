// Input validators for forms
class Validators {
  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // Required field validator
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }
    return null;
  }

  // Student ID validator
  static String? studentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mã sinh viên không được để trống';
    }
    if (value.length < 6) {
      return 'Mã sinh viên phải có ít nhất 6 ký tự';
    }
    return null;
  }

  // Phone validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ (10-11 chữ số)';
    }
    return null;
  }

  // Session code validator
  static String? sessionCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mã buổi học không được để trống';
    }
    if (value.length < 3) {
      return 'Mã buổi học phải có ít nhất 3 ký tự';
    }
    return null;
  }

  // Class code validator
  static String? classCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mã lớp không được để trống';
    }
    if (value.length < 3) {
      return 'Mã lớp phải có ít nhất 3 ký tự';
    }
    return null;
  }

  // Min length validator
  static String? minLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }
    if (value.length < length) {
      return '${fieldName ?? "Trường này"} phải có ít nhất $length ký tự';
    }
    return null;
  }

  // Max length validator
  static String? maxLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length > length) {
      return '${fieldName ?? "Trường này"} không được vượt quá $length ký tự';
    }
    return null;
  }

  // Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}

