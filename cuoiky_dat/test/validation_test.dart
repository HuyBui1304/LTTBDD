import 'package:flutter_test/flutter_test.dart';
import 'package:cuoiky_dat/utils/validation.dart';

void main() {
  group('Validation Tests', () {
    test('validateName - should return null for valid name', () {
      expect(Validation.validateName('Nguyen Van A'), isNull);
      expect(Validation.validateName('Trần Thị B'), isNull);
    });

    test('validateName - should return error for empty name', () {
      expect(Validation.validateName(null), isNotNull);
      expect(Validation.validateName(''), isNotNull);
      expect(Validation.validateName('   '), isNotNull);
    });

    test('validateName - should return error for short name', () {
      expect(Validation.validateName('A'), isNotNull);
      expect(Validation.validateName('B'), isNotNull);
    });

    test('validateEmail - should return null for valid email', () {
      expect(Validation.validateEmail('test@example.com'), isNull);
      expect(Validation.validateEmail('user.name@domain.co.uk'), isNull);
    });

    test('validateEmail - should return error for invalid email', () {
      expect(Validation.validateEmail(null), isNotNull);
      expect(Validation.validateEmail(''), isNotNull);
      expect(Validation.validateEmail('invalid-email'), isNotNull);
      expect(Validation.validateEmail('test@'), isNotNull);
      expect(Validation.validateEmail('@example.com'), isNotNull);
    });

    test('validatePhone - should return null for valid phone', () {
      expect(Validation.validatePhone('0123456789'), isNull);
      expect(Validation.validatePhone('09876543210'), isNull);
      expect(Validation.validatePhone('0123-456-789'), isNull); // Should handle dashes
    });

    test('validatePhone - should return error for invalid phone', () {
      expect(Validation.validatePhone(null), isNotNull);
      expect(Validation.validatePhone(''), isNotNull);
      expect(Validation.validatePhone('12345'), isNotNull); // Too short
      expect(Validation.validatePhone('123456789012'), isNotNull); // Too long
      expect(Validation.validatePhone('abc1234567'), isNotNull); // Contains letters
    });

    test('validateStudentId - should return null for valid student ID', () {
      expect(Validation.validateStudentId('SV001'), isNull);
      expect(Validation.validateStudentId('123456'), isNull);
    });

    test('validateStudentId - should return error for invalid student ID', () {
      expect(Validation.validateStudentId(null), isNotNull);
      expect(Validation.validateStudentId(''), isNotNull);
      expect(Validation.validateStudentId('AB'), isNotNull); // Too short
    });

    test('validateTime - should return null for valid time', () {
      expect(Validation.validateTime('08:00'), isNull);
      expect(Validation.validateTime('23:59'), isNull);
      expect(Validation.validateTime('14:30'), isNull);
    });

    test('validateTime - should return error for invalid time', () {
      expect(Validation.validateTime(null), isNotNull);
      expect(Validation.validateTime(''), isNotNull);
      expect(Validation.validateTime('8:00'), isNotNull); // Missing leading zero
      expect(Validation.validateTime('25:00'), isNotNull); // Invalid hour
      expect(Validation.validateTime('12:60'), isNotNull); // Invalid minute
      expect(Validation.validateTime('12:5'), isNotNull); // Missing leading zero in minute
    });

    test('validateNotEmpty - should return null for non-empty value', () {
      expect(Validation.validateNotEmpty('value', 'field'), isNull);
      expect(Validation.validateNotEmpty('text', 'field'), isNull);
    });

    test('validateNotEmpty - should return error for empty value', () {
      expect(Validation.validateNotEmpty(null, 'field'), isNotNull);
      expect(Validation.validateNotEmpty('', 'field'), isNotNull);
      expect(Validation.validateNotEmpty('   ', 'field'), isNotNull);
    });
  });
}

