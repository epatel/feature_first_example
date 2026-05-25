# Feature: inventory (full contract)

Pipeline that checks warehouse stock levels and flags low-stock items.

## Nodes

### check_stock
- **Expects:** nothing (queries warehouse directly)
- **Produces:** `stock` — `Map<String, int>` (item name → quantity)
- **Hook guidance:** Use `after` to react to stock levels or adjust availability (e.g. pending returns increase available count).

### low_stock
- **Expects:** `stock`
- **Produces:** `low_stock_items` — `List<String>` (item names below threshold)
- **Hook guidance:** Use `after` to trigger alerts, reorder, or notify customers.

## Context keys

| Key               | Type              | Written by       | Read by    |
|-------------------|-------------------|------------------|------------|
| `stock`           | `Map<String,int>` | check_stock      | low_stock  |
| `low_stock_items` | `List<String>`    | low_stock        |            |
| `customer_alert`  | `String?`         | place-order hook |            |

## Existing hooks from other features

- **place-order** → `low_stock.after` [static] — sends customer alert when items are low

## This feature hooks into

- **place-order** → `validate_cart.before` [static] — aborts order if items are out of stock
- **place-order** → (not yet wired) `confirm_order.after` could decrement stock

## How to add behavior

To adjust available stock (e.g. for pending returns):
```dart
engine.bind('inventory.check_stock', HookPoint.after, 'returns',
    (ctx, node) async {
  final stock = ctx['stock'] as Map<String, int>;
  stock['widget'] = stock['widget']! + pendingReturnCount;
});
```
