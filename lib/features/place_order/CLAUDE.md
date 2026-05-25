# Feature: place-order

Order processing pipeline: validate_cart → calculate_totals → charge_payment → confirm_order

## Key constraints

- Do NOT set `ctx['total']` directly — add to `ctx['discounts']` and let calculate_totals compute it
- Does NOT own: stock checks (inventory), pricing adjustments or fraud detection (dynamic hooks)
- inventory hooks into `validate_cart.before` [static] — can abort for out-of-stock items
- analytics hooks into `*.after` [static] — observes all nodes, appends to `ctx['metrics']`

For full node docs, context keys table, and code examples see @CLAUDE_full.md
