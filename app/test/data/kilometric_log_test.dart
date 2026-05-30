import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/kilometric_log.dart';

void main() {
  group('KilometricLog.computeAnnual5cv2024 (#291)', () {
    test('0 km -> 0', () {
      expect(KilometricLog.computeAnnual5cv2024(0), 0);
    });
    test('palier 1 : 3000 km -> 3000 * 0.636 = 1908', () {
      expect(KilometricLog.computeAnnual5cv2024(3000), closeTo(1908, 0.01));
    });
    test('palier 2 : 10000 km -> 10000 * 0.357 + 1395 = 4965', () {
      expect(KilometricLog.computeAnnual5cv2024(10000), closeTo(4965, 0.01));
    });
    test('palier 3 : 25000 km -> 25000 * 0.427 = 10675', () {
      expect(KilometricLog.computeAnnual5cv2024(25000), closeTo(10675, 0.01));
    });
    test('km negatif -> 0', () {
      expect(KilometricLog.computeAnnual5cv2024(-100), 0);
    });
  });
}
