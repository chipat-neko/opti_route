import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/widgets/stop_action_sheet.dart';

void main() {
  group('StopAction sealed types', () {
    test('MarkLivreAction', () {
      const a = MarkLivreAction();
      expect(a, isA<StopAction>());
    });

    test('MarkEchecAction porte une raison', () {
      const a = MarkEchecAction('absent');
      expect(a, isA<StopAction>());
      expect(a.raison, 'absent');
    });

    test('MarkAaLivrerAction', () {
      const a = MarkAaLivrerAction();
      expect(a, isA<StopAction>());
    });

    test('OpenDetailsAction', () {
      const a = OpenDetailsAction();
      expect(a, isA<StopAction>());
    });
  });
}
