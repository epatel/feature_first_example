import '../../feature_engine.dart';

extension PlaceOrderContext on Context {
  bool get validated => this['validated'] as bool;
  set validated(bool v) => this['validated'] = v;

  List<Map<String, dynamic>> get cart =>
      this['cart'] as List<Map<String, dynamic>>;
  set cart(List<Map<String, dynamic>> v) => this['cart'] = v;

  List<double> get discounts =>
      (this['discounts'] as List<double>?) ?? <double>[];
  set discounts(List<double> v) => this['discounts'] = v;

  double get total => this['total'] as double;
  set total(double v) => this['total'] = v;

  String get paymentStatus => this['payment_status'] as String;
  set paymentStatus(String v) => this['payment_status'] = v;

  String get orderId => this['order_id'] as String;
  set orderId(String v) => this['order_id'] = v;
}

Feature definePlaceOrder(Engine engine) {
  final f = engine.feature('place-order');

  f.addNode('validate_cart', (ctx) async {
    ctx.validated = true;
  });

  f.addNode('calculate_totals', (ctx) async {
    var sum = ctx.cart.fold<double>(
        0, (acc, item) => acc + (item['price'] as double));
    for (final d in ctx.discounts) {
      sum -= d;
    }
    ctx.total = sum;
  });

  f.addNode('charge_payment', (ctx) async {
    ctx.paymentStatus = 'charged';
  });

  f.addNode('confirm_order', (ctx) async {
    ctx.orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  });

  return f;
}
