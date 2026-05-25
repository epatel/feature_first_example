# Feature: inventory

Stock level pipeline: check_stock → low_stock

## Key constraints

- place-order hooks into `low_stock.after` [static] — sends customer alerts on low stock
- This feature hooks into place-order `validate_cart.before` [static] — can abort for out-of-stock
- `confirm_order.after` stock decrement is not yet wired

For full node docs, context keys table, and code examples see @CLAUDE_full.md
