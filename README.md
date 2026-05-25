# Feature-First Structured Example

A Flutter web app demonstrating the feature-first structured architecture — where each feature is a pipeline of hookable nodes and features act as middleware for each other.

See `CLAUDE.md` for the card index — lazy-loaded reference cards covering architecture, domains, features, and decisions.

## Running

```bash
flutter run -d chrome
```

## What it demonstrates

The app has a control panel (left) and a trace log (right). You can:

- **Run feature pipelines** — place an order or check inventory, see the execution trace
- **Toggle dynamic hooks** — bind/unbind holiday pricing, fraud checks, or a debug observer at runtime
- **See bi-directional composition** — inventory hooks into place-order (stock validation), place-order hooks back into inventory (low-stock alerts)

## Project structure

```
lib/
  feature_engine.dart              Core framework (Engine, Feature, Node, Context)
  demo_setup.dart                  Feature registration + static hook wiring
  demo_page.dart                   Demo page state and engine interaction
  main.dart                        App entry point
  features/
    place_order/                   Order processing pipeline (4 nodes)
    inventory/                     Stock level pipeline (2 nodes)
  widgets/
    control_panel.dart             Action buttons, hook toggles, static hook display
    log_view.dart                  Execution trace output
cards/
  architecture.md                  Component connections and data flow
  feature-engine.md                Core runtime: Engine, Feature, Node, Context, HookHandle
  place-order.md                   Order processing domain
  inventory.md                     Stock management domain
  hook-wiring.md                   Static and dynamic hook patterns
  feature-first-over-layered.md    Architecture decision record
test/
  feature_engine_test.dart         26 tests covering the engine and demo setup
```

## Tests

```bash
flutter test test/feature_engine_test.dart
```
