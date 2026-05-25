import '../../feature_engine.dart';

Feature definePlaceOrder(Engine engine) {
  final f = engine.feature('place-order');

  f.addNode('validate_cart', (ctx) async {
    ctx['validated'] = true;
  });

  f.addNode('calculate_totals', (ctx) async {
    final items = ctx['cart'] as List<Map<String, dynamic>>;
    var total =
        items.fold<double>(0, (sum, item) => sum + (item['price'] as double));
    for (final d in (ctx['discounts'] as List<double>?) ?? <double>[]) {
      total -= d;
    }
    ctx['total'] = total;
  });

  f.addNode('charge_payment', (ctx) async {
    ctx['payment_status'] = 'charged';
  });

  f.addNode('confirm_order', (ctx) async {
    ctx['order_id'] = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  });

  return f;
}
