import 'feature_engine.dart';
import 'features/place_order/place_order.dart';
import 'features/inventory/inventory.dart';

Engine buildDemoEngine() {
  final engine = Engine();

  definePlaceOrder(engine);
  defineInventory(engine);

  // ── Static hooks (bi-directional) ─────────────────────────────

  // inventory -> place-order: stock validation
  engine.bind('place-order.validate_cart', HookPoint.before, 'inventory',
      (ctx, node) async {
    final cart = ctx['cart'] as List<Map<String, dynamic>>?;
    if (cart == null) return;
    for (final item in cart) {
      if (item['name'] == 'gadget') {
        ctx.abort('Out of stock: ${item['name']}');
        return;
      }
    }
  });

  // place-order -> inventory: alert on low stock
  engine.bind('inventory.low_stock', HookPoint.after, 'place-order',
      (ctx, node) async {
    final low = ctx.lowStockItems;
    if (low.isNotEmpty) {
      ctx['customer_alert'] = 'Low stock warning sent for: ${low.join(', ')}';
    }
  });

  // analytics -> place-order: observe all nodes
  engine.bind('place-order.*', HookPoint.after, 'analytics',
      (ctx, node) async {
    final metrics = (ctx['metrics'] as List<String>?) ?? [];
    metrics.add(node);
    ctx['metrics'] = metrics;
  });

  return engine;
}

Context makeCart(List<Map<String, dynamic>> items, {String? risk}) {
  final ctx = Context();
  ctx.cart = items;
  if (risk != null) ctx['customer_risk'] = risk;
  return ctx;
}
