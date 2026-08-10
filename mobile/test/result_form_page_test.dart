import 'package:flutter_test/flutter_test.dart';
import 'package:sscs_mobile/features/results/result_form_page.dart';

void main() {
  group('normalizeMarksInput', () {
    test('preserves values for custom total-mark scales', () {
      expect(normalizeMarksInput('125'), '125');
      expect(normalizeMarksInput('20'), '20');
    });

    test('clamps negatives to 0', () {
      expect(normalizeMarksInput('-5'), '0');
    });
  });

  group('buildResultPayload', () {
    test('includes notify_parents false for save-only mode', () {
      final payload = buildResultPayload(
        studentId: 'student-1',
        assignmentId: 'assignment-1',
        marksObtained: 85,
        totalMarks: 100,
        grade: 'B',
        examTypeValue: 'quiz',
        examDate: '2026-08-02',
        remarks: 'Great work',
        notifyParents: false,
      );

      expect(payload['notify_parents'], isFalse);
      expect(payload['student_id'], 'student-1');
      expect(payload['marks_obtained'], 85);
      expect(payload['total_marks'], 100);
      expect(payload['remarks'], 'Great work');
    });

    test('includes notify_parents true for save-and-send mode', () {
      final payload = buildResultPayload(
        studentId: 'student-2',
        assignmentId: 'assignment-2',
        marksObtained: 92,
        totalMarks: 100,
        grade: 'A',
        examTypeValue: 'final',
        examDate: '2026-08-02',
        remarks: null,
        notifyParents: true,
      );

      expect(payload['notify_parents'], isTrue);
      expect(payload['student_id'], 'student-2');
      expect(payload.containsKey('remarks'), isFalse);
    });
  });
}
