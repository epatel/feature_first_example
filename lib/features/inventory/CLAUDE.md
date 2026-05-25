# Feature: inventory

Stock level pipeline: check_stock → low_stock.

**Public surface**: `defineInventory(engine)` registers the feature and its two nodes.

**Owns**: stock querying, low-stock detection.
**Does not own**: stock modification after order (not yet wired), customer-facing alerts (place-order hook handles).

## Nodes

### check_stock
- **Expects:** nothing (queries warehouse directly)
- **Produces:** `stock` — `Map<String, int>` (item name → quantity; hardcoded: widget=5, gadget=0, doohickey=12)
- **Hook guidance:** Use `after` to react to stock levels or adjust availability.

### low_stock
- **Expects:** `stock`
- **Produces:** `low_stock_items` — `List<String>` (item names below threshold of 3)
- **Hook guidance:** Use `after` to trigger alerts, reorder, or notify customers.

## Context keys

| Key               | Type              | Written by       | Read by    |
|-------------------|-------------------|------------------|------------|
| `stock`           | `Map<String,int>` | check_stock      | low_stock  |
| `low_stock_items` | `List<String>`    | low_stock        |            |
| `customer_alert`  | `String?`         | place-order hook |            |

## Hooks

**Hooked by:**
- **place-order** → `low_stock.after` [static] — sends customer alert when items are low

**Hooks into:**
- **place-order** → `validate_cart.before` [static] — aborts order if cart contains out-of-stock items
- **place-order** → `confirm_order.after` [not yet wired] — could decrement stock

## How to add behavior

To adjust available stock (e.g. for pending returns):
```dart
engine.bind('inventory.check_stock', HookPoint.after, 'returns',
    (ctx, node) async {
  final stock = ctx['stock'] as Map<String, int>;
  stock['widget'] = stock['widget']! + pendingReturnCount;
});
```
