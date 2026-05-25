import '../../feature_engine.dart';

Feature defineInventory(Engine engine) {
  final f = engine.feature('inventory');

  f.addNode('check_stock', (ctx) async {
    ctx['stock'] = {'widget': 5, 'gadget': 0, 'doohickey': 12};
  });

  f.addNode('low_stock', (ctx) async {
    final stock = ctx['stock'] as Map<String, int>;
    final low =
        stock.entries.where((e) => e.value < 3).map((e) => e.key).toList();
    ctx['low_stock_items'] = low;
  });

  return f;
}
