class Validation {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validateStudentId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã sinh viên';
    }
    if (value.trim().length < 3) {
      return 'Mã sinh viên phải có ít nhất 3 ký tự';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Số điện thoại không hợp lệ (10-11 chữ số)';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  static String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thời gian';
    }
    final timeRegex = RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value.trim())) {
      return 'Thời gian không hợp lệ (định dạng: HH:mm)';
    }
    return null;
  }
}
