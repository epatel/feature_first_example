# place-order

Order processing pipeline: validate_cart → calculate_totals → charge_payment → confirm_order.

**Purpose**: Process a customer order from cart validation through payment to confirmation.

**Public surface**: `definePlaceOrder(engine)` registers the feature and its four nodes.

**Key types and concepts**: `cart` (list of {name, price} maps), `discounts` (list of doubles subtracted from total), `total`, `payment_status`, `order_id`.

**Owns**: cart validation, total calculation, payment charging, order confirmation.

**Does not own**: stock availability (inventory feature), pricing adjustments (dynamic hooks), fraud detection (dynamic hooks), analytics (static hook).

**Context keys**:

| Key | Type | Written by | Read by |
|---|---|---|---|
| `cart` | `List<Map>` | caller | validate_cart, calculate_totals |
| `validated` | `bool` | validate_cart | — |
| `discounts` | `List<double>?` | hooks (before calculate_totals) | calculate_totals |
| `total` | `double` | calculate_totals | charge_payment |
| `payment_status` | `String` | charge_payment | confirm_order |
| `order_id` | `String` | confirm_order | — |
| `metrics` | `List<String>?` | analytics hook | — |
| `customer_risk` | `String?` | caller | fraud hook |

**Critical invariant**: never set `ctx['total']` directly — add to `ctx['discounts']` and let calculate_totals compute the result.

**Hooked by**: inventory (validate_cart.before, static), analytics (*.after, static), holiday_pricing (calculate_totals.before, dynamic), fraud (charge_payment.before, dynamic), debug (*.before, dynamic).
