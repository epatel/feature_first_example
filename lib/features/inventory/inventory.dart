import '../../feature_engine.dart';

extension InventoryContext on Context {
  Map<String, int> get stock => this['stock'] as Map<String, int>;
  set stock(Map<String, int> v) => this['stock'] = v;

  List<String> get lowStockItems => this['low_stock_items'] as List<String>;
  set lowStockItems(List<String> v) => this['low_stock_items'] = v;

  String? get customerAlert => this['customer_alert'] as String?;
  set customerAlert(String? v) => this['customer_alert'] = v;
}

Feature defineInventory(Engine engine) {
  final f = engine.feature('inventory');

  f.addNode('check_stock', (ctx) async {
    ctx.stock = {'widget': 5, 'gadget': 0, 'doohickey': 12};
  });

  f.addNode('low_stock', (ctx) async {
    final low =
        ctx.stock.entries.where((e) => e.value < 3).map((e) => e.key).toList();
    ctx.lowStockItems = low;
  });

  return f;
}
