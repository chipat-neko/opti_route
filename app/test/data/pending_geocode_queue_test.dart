import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/pending_geocode_queue.dart';

void main() {
  group('PendingGeocodeQueue (#297)', () {
    test('vide a l\'init', () {
      final q = PendingGeocodeQueue();
      expect(q.isEmpty, isTrue);
      expect(q.length, 0);
      expect(q.snapshot(), isEmpty);
    });

    test('enqueue idempotent', () {
      final q = PendingGeocodeQueue();
      q.enqueue(1);
      q.enqueue(1);
      q.enqueue(2);
      expect(q.length, 2);
    });

    test('drain vide la queue + retourne snapshot', () {
      final q = PendingGeocodeQueue();
      q.enqueue(1);
      q.enqueue(2);
      final drained = q.drain();
      expect(drained.toSet(), {1, 2});
      expect(q.isEmpty, isTrue);
    });

    test('remove cible', () {
      final q = PendingGeocodeQueue();
      q.enqueue(1);
      q.enqueue(2);
      q.remove(1);
      expect(q.snapshot(), [2]);
    });

    test('enqueue rejette ids invalides', () {
      final q = PendingGeocodeQueue();
      q.enqueue(0);
      q.enqueue(-1);
      expect(q.isEmpty, isTrue);
    });
  });
}
