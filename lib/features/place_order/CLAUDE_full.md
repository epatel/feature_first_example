# Feature: place-order (full contract)

Pipeline that processes a customer order from cart to confirmation.

**Public surface**: `definePlaceOrder(engine)` registers the feature and its four nodes.

**Owns**: cart validation, total calculation, payment charging, order confirmation.
**Does not own**: stock availability (inventory feature), pricing adjustments (dynamic hooks), fraud detection (dynamic hooks), analytics (static hook).

## Nodes

### validate_cart
- **Expects:** `cart` — `List<Map>` with `name` (String) and `price` (double) per item
- **Produces:** `validated` — `bool`
- **Hook guidance:** Use `before` to add custom validation or reject invalid state. Use `after` to observe the validated cart.

### calculate_totals
- **Expects:** `cart`, optionally `discounts` — `List<double>`
- **Produces:** `total` — `double`
- **Hook guidance:** Use `before` to inject discounts, tax overrides, or currency conversion. Do not set `total` directly — add to `discounts` and let the node compute.

### charge_payment
- **Expects:** `total`
- **Produces:** `payment_status` — `String` (`'charged'`)
- **Hook guidance:** Use `before` to swap payment provider or add fraud checks. Use `after` to trigger receipts.

### confirm_order
- **Expects:** `payment_status`
- **Produces:** `order_id` — `String` (format: `ORD-<timestamp>`)
- **Hook guidance:** Use `before` to enrich the order with metadata. Use `after` to trigger fulfillment, notifications, or analytics.

## Context keys

| Key              | Type                    | Written by         | Read by              |
|------------------|-------------------------|--------------------|----------------------|
| `cart`           | `List<Map>`             | caller             | validate_cart, calculate_totals |
| `validated`      | `bool`                  | validate_cart       |                      |
| `discounts`      | `List<double>?`         | hooks (before calc) | calculate_totals     |
| `total`          | `double`                | calculate_totals    | charge_payment       |
| `payment_status` | `String`                | charge_payment      | confirm_order        |
| `order_id`       | `String`                | confirm_order       |                      |
| `metrics`        | `List<String>?`         | analytics hook      |                      |
| `customer_risk`  | `String?`               | caller              | fraud hook           |

## Existing hooks from other features

**Static:**
- **inventory** → `validate_cart.before` — aborts if cart contains out-of-stock items
- **analytics** → `*.after` — observes all nodes, appends node name to `metrics`

**Dynamic (bound/unbound at runtime):**
- **holiday_pricing** → `calculate_totals.before` — injects a $5 discount into `ctx['discounts']`
- **fraud** → `charge_payment.before` — bound per-request for high-risk customers (`ctx['customer_risk'] == 'high'`), unbound after run
- **debug** → `*.before` — wildcard observer on all nodes

## How to add behavior

To add a discount:
```dart
engine.bind('place-order.calculate_totals', HookPoint.before, 'my-discount',
    (ctx, node) async {
  final d = (ctx['discounts'] as List<double>?) ?? [];
  d.add(5.0);
  ctx['discounts'] = d;
});
```

Do NOT set `ctx['total']` directly — the node computes it from `cart` minus `discounts`.
