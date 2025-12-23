import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('Email Validator', () {
      test('should return null for valid email', () {
        expect(Validators.email('test@example.com'), null);
        expect(Validators.email('user.name@domain.co.uk'), null);
      });

      test('should return error for invalid email', () {
        expect(Validators.email('invalid'), isNotNull);
        expect(Validators.email('test@'), isNotNull);
        expect(Validators.email('@example.com'), isNotNull);
      });

      test('should return error for empty email', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });
    });

    group('Required Validator', () {
      test('should return null for non-empty value', () {
        expect(Validators.required('Hello'), null);
        expect(Validators.required('123'), null);
      });

      test('should return error for empty value', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required('   '), isNotNull);
        expect(Validators.required(null), isNotNull);
      });

      test('should use custom field name in error message', () {
        final result = Validators.required(null, fieldName: 'Tên');
        expect(result, contains('Tên'));
      });
    });

    group('Student ID Validator', () {
      test('should return null for valid student ID', () {
        expect(Validators.studentId('SV0001'), null);
        expect(Validators.studentId('123456'), null);
        expect(Validators.studentId('STUDENT001'), null);
      });

      test('should return error for short student ID', () {
        expect(Validators.studentId('SV1'), isNotNull);
        expect(Validators.studentId('12345'), isNotNull);
      });

      test('should return error for empty student ID', () {
        expect(Validators.studentId(''), isNotNull);
        expect(Validators.studentId(null), isNotNull);
      });
    });

    group('Phone Validator', () {
      test('should return null for valid phone', () {
        expect(Validators.phone('0123456789'), null);
        expect(Validators.phone('01234567890'), null);
      });

      test('should return null for empty phone (optional)', () {
        expect(Validators.phone(''), null);
        expect(Validators.phone(null), null);
      });

      test('should return error for invalid phone', () {
        expect(Validators.phone('123'), isNotNull);
        expect(Validators.phone('abcdefghij'), isNotNull);
        expect(Validators.phone('012345678901234'), isNotNull);
      });
    });

    group('Session Code Validator', () {
      test('should return null for valid session code', () {
        expect(Validators.sessionCode('SS001'), null);
        expect(Validators.sessionCode('SESSION-01'), null);
      });

      test('should return error for short session code', () {
        expect(Validators.sessionCode('SS'), isNotNull);
        expect(Validators.sessionCode('A'), isNotNull);
      });

      test('should return error for empty session code', () {
        expect(Validators.sessionCode(''), isNotNull);
        expect(Validators.sessionCode(null), isNotNull);
      });
    });

    group('Class Code Validator', () {
      test('should return null for valid class code', () {
        expect(Validators.classCode('IT01'), null);
        expect(Validators.classCode('CLASS-A'), null);
      });

      test('should return error for short class code', () {
        expect(Validators.classCode('IT'), isNotNull);
        expect(Validators.classCode('A'), isNotNull);
      });

      test('should return error for empty class code', () {
        expect(Validators.classCode(''), isNotNull);
        expect(Validators.classCode(null), isNotNull);
      });
    });

    group('Min Length Validator', () {
      test('should return null for value meeting min length', () {
        expect(Validators.minLength('Hello', 5), null);
        expect(Validators.minLength('Testing', 5), null);
      });

      test('should return error for value below min length', () {
        expect(Validators.minLength('Hi', 5), isNotNull);
        expect(Validators.minLength('Test', 5), isNotNull);
      });

      test('should return error for empty value', () {
        expect(Validators.minLength('', 5), isNotNull);
        expect(Validators.minLength(null, 5), isNotNull);
      });
    });

    group('Max Length Validator', () {
      test('should return null for value within max length', () {
        expect(Validators.maxLength('Hello', 10), null);
        expect(Validators.maxLength('Test', 10), null);
        expect(Validators.maxLength(null, 10), null);
      });

      test('should return error for value exceeding max length', () {
        expect(Validators.maxLength('Hello World!', 10), isNotNull);
        expect(Validators.maxLength('Testing Long Text', 10), isNotNull);
      });
    });

    group('Combine Validators', () {
      test('should pass all validators', () {
        final validator = Validators.combine([
          Validators.required,
          (v) => Validators.minLength(v, 5),
        ]);

        expect(validator('Hello'), null);
        expect(validator('Testing'), null);
      });

      test('should fail on first validator error', () {
        final validator = Validators.combine([
          Validators.required,
          (v) => Validators.minLength(v, 5),
        ]);

        expect(validator(''), isNotNull);
        expect(validator('Hi'), isNotNull);
      });

      test('should fail on second validator error', () {
        final validator = Validators.combine([
          Validators.required,
          (v) => Validators.minLength(v, 10),
        ]);

        expect(validator('Hello'), isNotNull);
      });
    });
  });
}

