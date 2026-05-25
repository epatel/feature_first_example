# inventory

Stock level pipeline: check_stock → low_stock.

**Purpose**: Query warehouse stock levels and identify items below threshold.

**Public surface**: `defineInventory(engine)` registers the feature and its two nodes.

**Key types and concepts**: `stock` (map of item name to quantity), `low_stock_items` (list of item names below threshold of 3), `customer_alert` (string set by place-order's hook).

**Owns**: stock querying, low-stock detection.

**Does not own**: stock modification after order (not yet wired), customer-facing alerts (place-order hook handles this).

**Context keys**:

| Key | Type | Written by | Read by |
|---|---|---|---|
| `stock` | `Map<String, int>` | check_stock | low_stock |
| `low_stock_items` | `List<String>` | low_stock | — |
| `customer_alert` | `String?` | place-order hook | — |

**Hooks into other features**: place-order.validate_cart.before (static) — aborts order if cart contains out-of-stock items (checks item name against hardcoded stock: widget=5, gadget=0, doohickey=12).

**Hooked by**: place-order (low_stock.after, static) — sends customer alert when low-stock items are detected.

**Known gap**: `confirm_order.after` stock decrement is not yet wired — stock levels are never reduced by orders.
