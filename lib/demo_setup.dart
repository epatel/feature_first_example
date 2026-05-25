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
    for (final item in ctx.cart) {
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
      ctx.customerAlert = 'Low stock warning sent for: ${low.join(', ')}';
    }
  });

  // analytics -> place-order: observe all nodes
  engine.bind('place-order.*', HookPoint.after, 'analytics',
      (ctx, node) async {
    final m = ctx.metrics;
    m.add(node);
    ctx.metrics = m;
  });

  return engine;
}

Context makeCart(List<Map<String, dynamic>> items, {String? risk}) {
  final ctx = Context();
  ctx.cart = items;
  if (risk != null) ctx.customerRisk = risk;
  return ctx;
}
