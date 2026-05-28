import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/chef_presence_service.dart';

/// Tests de la logique pure de fraicheur des positions live (carte
/// #174) : seuils fresh < 60s, recent < 300s, stale au-dela.
void main() {
  test('freshnessOf : seuils fresh / recent / stale', () {
    expect(freshnessOf(const Duration(seconds: 0)), LiveFreshness.fresh);
    expect(freshnessOf(const Duration(seconds: 59)), LiveFreshness.fresh);
    // 60s pile = plus "fresh" (seuil strict <60).
    expect(freshnessOf(const Duration(seconds: 60)), LiveFreshness.recent);
    expect(freshnessOf(const Duration(seconds: 299)), LiveFreshness.recent);
    // 300s pile = stale.
    expect(freshnessOf(const Duration(seconds: 300)), LiveFreshness.stale);
    expect(freshnessOf(const Duration(minutes: 10)), LiveFreshness.stale);
  });
}
